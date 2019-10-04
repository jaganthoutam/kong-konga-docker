return {
  fields = {
    header_to_check = {
      type = "string",
      default = "User-Agent"
    },
    allowed_header_values = {
      type = "array",
      default = {
        "secretAgent"
      }
    }
  }
}
