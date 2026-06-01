provider "aws" {
  region = "us-east-1"
}


variable "developer_team" {
    type = object({
      dev_username = list(string)
      team_name = string
    })
    

    validation {
    condition     = substr(var.developer_team["team_name"], 0, 4) == "dev-"
    error_message = "The name of the team must start with dev-"
   }

    default = {
      dev_username = [ "user1", "user2", "user3" ]
      team_name = "dev-team"
    }
}


resource "aws_iam_user" "users" {
  
  for_each = toset(var.developer_team["dev_username"])
  name = each.key

  tags = {
    tag-key = "${var.developer_team["team_name"]}"
  }

   lifecycle {
    precondition {
      condition     = length(var.developer_team["dev_username"]) >= 2
      error_message = "we need two or more developers to call the API"
    }
  }
    
}

output "users_arns" {
  description = "A mapped dictionary of IAM Usernames to their AWS ARNs"
  value = {for user in aws_iam_user.users : user.name => user.arn } 
}
/* Sintax optimization:

1. Object Attribute Notation (Dot vs. Bracket)
In your code, you accessed the object properties using bracket notation: var.developer_team["team_name"].

While Terraform will technically allow this, standard best practice dictates that we use dot notation for object types, and reserve bracket notation for map types.

Standard approach: var.developer_team.team_name

Standard approach: var.developer_team.dev_username

2. Unnecessary String Interpolation
In your tags block, you wrapped the variable in string interpolation: tag-key = "${var.developer_team["team_name"]}".

If a variable is the only thing being assigned, you don't need the quotes or the ${} brackets. You only need interpolation if you are combining the variable with other text (like you did in the error_message).

Cleaner approach: tag-key = var.developer_team.team_name  */
