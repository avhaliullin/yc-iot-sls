data "archive_file" "iot_boilerplate_src" {
  output_path = "${path.module}/dist/iot-bp-src.zip"
  type        = "zip"
  source_dir  = "${path.module}/src"
}

resource "yandex_function" "iot_handler" {
  entrypoint         = "index.handler"
  memory             = 128
  name               = "iot-handler"
  runtime            = "python311"
  user_hash          = data.archive_file.iot_boilerplate_src.output_base64sha256
  execution_timeout  = 10
  content {
    zip_filename = data.archive_file.iot_boilerplate_src.output_path
  }
}

resource "yandex_iam_service_account" "iot_trigger" {
  name = "iot-trigger"
}

resource "yandex_function_iam_binding" "iot_trigger_invoke_function" {
  function_id = yandex_function.iot_handler.id
  members     = ["serviceAccount:${yandex_iam_service_account.iot_trigger.id}"]
  role        = "serverless.functions.invoker"
}

resource "yandex_function_trigger" "iot" {
  name = "iot"
  function {
    id                 = yandex_function.iot_handler.id
    service_account_id = yandex_iam_service_account.iot_trigger.id
  }
  iot {
    registry_id = var.iot-registry-id
    topic = "$devices/+/events"
  }
  depends_on = [yandex_function_iam_binding.iot_trigger_invoke_function]
}

# configuration
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  folder_id = var.folder-id
  token     = var.yc-token
}

variable "iot-registry-id" {
  type = string
}

variable "folder-id" {
  type = string
}

variable "yc-token" {
  type = string
}