namespace :nexus, :atavan do
  long  :atavan
  short :at

  state_config(
    {
      terraform: {
        s3: {
          bucket: %(atavan-terraform-state),
          key: %(atavan/terraform.tfstate),
          region: %(us-west-2),
          dynamodb_table: %(atavan-terraform-lock),
          encrypt: true
        }
      }
    }
  )

  # environments(
  #   {
  #     je: {
  #       long: :jedha,
  #       short: :je
  #     }
  #   }
  # )

  # terraform do
  #   backend(
  #     {
  #       s3: {
  #         bucket: %(atavan-terraform-state),
  #         key: %(atavan/terraform.tfstate),
  #         region: %(us-west-2),
  #         dynamodb_table: %(atavan-terraform-lock),
  #         encrypt: true
  #       }
  #     }
  #   )
  # end
end
