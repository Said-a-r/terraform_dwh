terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

locals {
  erp_seed_version = "1"

  raw_files = setunion(
    fileset(path.module, "datos_csv/*.csv"),
    fileset(path.module, "datos_xls/*.xlsx"),
  )

  erp_sql_scripts = [
    "01_crear_esquema.sql",
    "02_catalogos.sql",
    "03_datos_2024.sql",
    "04_datos_2025.sql",
  ]
}

# 1. Grupo de recursos y almacenamiento en Brazil South.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  allow_nested_items_to_be_public = true
  min_tls_version                 = "TLS1_2"
}

resource "azurerm_storage_container" "raw" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "raw_files" {
  for_each = local.raw_files

  name                   = each.value
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.raw.name
  type                   = "Block"
  source                 = "${path.module}/${each.value}"
  content_md5            = filemd5("${path.module}/${each.value}")
  content_type           = length(regexall("\\.csv$", lower(each.value))) > 0 ? "text/csv" : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
}

# 2. Servidor y bases Azure SQL en Brazil South.
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services_explicit" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "db" {
  for_each = toset([var.sql_database_name, "dw_tarea2dwh"])

  name                        = each.value
  server_id                   = azurerm_mssql_server.sql_server.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name                    = "GP_S_Gen5_1"
  max_size_gb                 = 32
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
}

# 3. Carga inicial de ERP: esquema, catalogos, datos 2024 y datos 2025.
resource "terraform_data" "erp_schema" {
  triggers_replace = [
    azurerm_mssql_database.db[var.sql_database_name].id,
    local.erp_seed_version,
  ]

  depends_on = [
    azurerm_mssql_firewall_rule.allow_azure_services,
  ]

  lifecycle {
    precondition {
      condition     = alltrue([for script in local.erp_sql_scripts : fileexists("${path.module}/sql/${script}")])
      error_message = "Deben existir los cuatro scripts SQL de carga ERP en sql/."
    }
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      SQL_SERVER      = azurerm_mssql_server.sql_server.fully_qualified_domain_name
      SQL_DATABASE    = azurerm_mssql_database.db[var.sql_database_name].name
      SQL_USER        = azurerm_mssql_server.sql_server.administrator_login
      SQLCMDPASSWORD  = azurerm_mssql_server.sql_server.administrator_login_password
      SQL_SCRIPT_DIR  = abspath("${path.module}/sql")
      SQL_SCRIPT_LIST = join(";", local.erp_sql_scripts)
    }

    command = <<-BASH
      set -e

      SQLCMD="/opt/mssql-tools/bin/sqlcmd"
      if [ ! -x "$SQLCMD" ]; then
        SQLCMD=$(command -v sqlcmd || true)
      fi
      if [ -z "$SQLCMD" ]; then
        echo "Instale mssql-tools antes de ejecutar Terraform."
        exit 1
      fi

      COMMON_ARGS="-S $SQL_SERVER -d $SQL_DATABASE -U $SQL_USER -b -r 1 -l 30"

      connected=0
      for i in $(seq 1 12); do
        if $SQLCMD $COMMON_ARGS -Q "SET NOCOUNT ON; SELECT 1;" > /dev/null 2>&1; then
          connected=1
          break
        fi
        sleep 10
      done

      if [ "$connected" -ne 1 ]; then
        echo "No se pudo conectar a la base ERP despues de crearla y configurar el firewall."
        exit 1
      fi

      IFS=';' read -ra SCRIPTS <<< "$SQL_SCRIPT_LIST"
      for script in "$${SCRIPTS[@]}"; do
        path="$SQL_SCRIPT_DIR/$script"
        if [ ! -f "$path" ]; then
          echo "No existe el script SQL: $path"
          exit 1
        fi
        echo "Ejecutando $script en $SQL_DATABASE"
        $SQLCMD $COMMON_ARGS -i "$path"
      done
    BASH
  }
}

# 4. Factoría de integración en East US.
resource "azurerm_data_factory" "adf" {
  name                = var.data_factory_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.data_factory_location
}