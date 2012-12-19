
define [
  'spine'
  'text!deployment.txt'
], (Spine, Deployment) ->
  
  class Session extends Spine.Model
    @configure "Session",
      "id"
    
    if Deployment is 'local'
      @extend Spine.Model.Local
    else
      @extend Spine.Model.Ajax
      @extend url: "/api/sessions"

