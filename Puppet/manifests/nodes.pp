node basenode {
  include cfn
}

node /^.*internal$/ inherits basenode {
  case $cfn_roles {
    /firstfuel-web/: {
      include firstfuel::web
    }
    /firstfuel-app/: {
      include firstfuel::app
    }
  }
}
