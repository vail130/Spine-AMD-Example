
define [
  'spine'
  'text!deployment.txt'
], (Spine, Deployment) ->
  
  class Account extends Spine.Model
    @configure "Account",
      "id"
      "first_name"
      "last_name"
      "email"
      "type"
      "status"
      "date_created"
      "date_updated"
      "unix_created"
      "unix_updated"
    
    if Deployment is 'local'
      @extend Spine.Model.Local
    else
      @extend Spine.Model.Ajax
      @extend url: "/api/accounts"

