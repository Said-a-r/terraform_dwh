# 🚀 Proyecto TAREA2DWH - Infraestructura en Azure con Terraform

Este repositorio contiene la infraestructura como código (IaC) para desplegar un entorno completo de datos en Azure utilizando **Terraform**. El proyecto incluye la creación de un Data Lake para datos crudos, bases de datos SQL para el ERP y el Data Warehouse, y un Azure Data Factory para la orquestación y limpieza de datos.

## 📋 Arquitectura del Proyecto

Terraform despliega automáticamente los siguientes recursos:

- **Resource Group**: Contenedor lógico de todos los recursos (`gr-ucb-tarea2dwh-8736`).
- **Storage Account (ADLS Gen2)**: Para almacenar los archivos crudos (`.csv` y `.xlsx`) en el contenedor `raw`.
- **Azure SQL Server**: Servidor lógico (`sql-tarea2dwh-8736`).
- **Azure SQL Databases**:
  - `tarea2dwh_db`: Base de datos origen (ERP).
  - `dw_tarea2dwh`: Base de datos destino (Data Warehouse).
- **Azure Data Factory**: Factoría de integración de datos (`adf-tarea2dwh-us-8736`).
- **Carga Automática (Local-Exec)**: Un script en Bash que ejecuta los archivos `.sql` locales para crear y poblar las tablas iniciales del ERP en la base de datos.

## ⚙️ Requisitos Previos

Antes de ejecutar este proyecto, asegúrate de tener instalado y configurado lo siguiente:

1. **Terraform** (v1.5.0 o superior).
   - [Guía de instalación oficial](https://developer.hashicorp.com/terraform/downloads)
2. **Azure CLI** (Opcional, si usas autenticación por consola).
   - [Guía de instalación oficial](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **SQLCMD (mssql-tools)**:
   - Dado que el proyecto ejecuta un script local en Bash para poblar la base de datos, necesitas tener `sqlcmd` instalado en tu sistema operativo.
   - *En Arch Linux / EndeavourOS:* `yay -S mssql-tools`
   - *En Ubuntu/Debian:* `sudo apt-get install mssql-tools`
   - **Importante:** Asegúrate de agregar `/opt/mssql-tools/bin` a tu variable `PATH`.
4. **Credenciales de Azure**: Necesitas un *Service Principal* (App ID, Password, Tenant ID y Subscription ID).

## 🚀 Pasos para Replicar el Proyecto

Sigue estos pasos para desplegar la infraestructura en tu propia cuenta de Azure.

### 1. Clonar el repositorio
```bash
# terraform.tfvars
subscription_id = "tu-subscription-id-aqui"
client_id       = "tu-app-id-aqui"
client_secret   = "tu-password-aqui"
tenant_id       = "tu-tenant-id-aqui"

# La contraseña debe cumplir con los requisitos de Azure (Mayúscula, minúscula, número y símbolo)
sql_admin_password = "TuPasswordSeguro123!"
git clone https://github.com/TU_USUARIO/TU_REPOSITORIO.git
cd TAREA2DWH
