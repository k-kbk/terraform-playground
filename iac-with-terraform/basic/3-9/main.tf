# variable "names" {
#   type    = list(string)
#   default = ["a", "b", "c"]
# }

# resource "local_file" "abc" {
#   count    = length(var.names)
#   content  = "abc"
#   filename = "${path.module}/abc-${var.names[count.index]}.txt"
# }

# resource "local_file" "def" {
#   count    = length(var.names)
#   content  = local_file.abc[count.index].content
#   filename = "${path.module}/def-${element(var.names, count.index)}.txt"
# }

# variable "names" {
#   default = {
#     a = "content a"
#     b = "content b"
#     c = "content c"
#   }
# }

# resource "local_file" "abc" {
#   for_each = var.names
#   content  = each.value
#   filename = "${path.module}/abc-${each.key}.txt"
# }

# resource "local_file" "def" {
#   for_each = local_file.abc
#   content  = each.value.content
#   filename = "${path.module}/def-${each.key}.txt"
# }

variable "names" {
  type    = list(string)
  default = ["a", "b", "c"]
}

resource "local_file" "abc" {
  content  = jsonencode([for name in var.names : upper(name)])
  filename = "${path.module}/abc.txt"
}

output "A_upper_value" {
  value = [for name in var.names : upper(name)]
}

output "B_index_and_value" {
  value = [for idx, name in var.names : "${idx} is ${name}"]
}

output "C_make_object" {
  value = { for name in var.names : name => upper(name) }
}

output "D_with_filter" {
  value = [for name in var.names : upper(name) if name != "a"]
}

variable "names_map" {
  default = {
    a = "content a"
    b = "content b"
    c = "content c"
  }
}

data "archive_file" "dotfiles" {
  type        = "zip"
  output_path = "${path.module}/files.zip"

  dynamic "source" {
    for_each = var.names_map
    content {
      content  = source.value
      filename = "dotfiles/${source.key}.txt"
    }
  }
}
