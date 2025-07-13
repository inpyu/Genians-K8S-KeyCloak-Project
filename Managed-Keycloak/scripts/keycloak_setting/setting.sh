
ADMIN_REALM=master
ADMIN_CLIENT_ID=admin-cli


# Keycloak에서 admin 액세스 토큰을 요청하는 함수
get_admin_access_token() {
ADMIN_ACCESS_TOKEN=$(curl -s -k -q -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" \
    -d "username=$ADMIN_USERNAME" \
    -d "password=$ADMIN_PASSWORD" \
    "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" | jq -r '.access_token')
}


# realm 생성
create_realm() {

    curl -X POST -k -g \
    -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" "$KEYCLOAK_URL/admin/realms" \
    -H "Content-Type: application/json" \
    --data '{"id": "'$1'","realm": "'$1'","accessTokenLifespan": 600,"enabled": true,"sslRequired": "all","bruteForceProtected": true,"loginTheme": "keycloak","eventsEnabled": false,"adminEventsEnabled": false}'
}

# 모든 클라이언트 ID를 출력
get_client_list() {
CLIENT_IDS=$(curl -s -k -X GET \
 -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
"$KEYCLOAK_URL/admin/realms/$REALM/clients"| jq -r '.[].clientId')

echo $CLIENT_IDS
}
#[{"id":"a28f2629-76d5-40ce-8342-0abb16c31c7c","clientId":"account","name":"${client_account}","rootUrl":"${authBaseUrl}","baseUrl":"/realms/minions/account/","surrogateAuthRequired":false,"enabled":true,"alwaysDisplayInConsole":false,"clientAuthenticatorType":"client-secret","redirectUris":["/realms/minions/account/*"],"webOrigins":[],"notBefore":0,"bearerOnly":false,"consentRequired":false,"standardFlowEnabled":true,"implicitFlowEnabled":false,"directAccessGrantsEnabled":false,"serviceAccountsEnabled":false,"publicClient":true,"frontchannelLogout":false,"protocol":"openid-connect","attributes":{"post.logout.redirect.uris":"+"},"authenticationFlowBindingOverrides":{},"fullScopeAllowed":false,"nodeReRegistrationTimeout":0,"defaultClientScopes":["web-origins","acr","profile","roles","email"],"optionalClientScopes":["address","phone","offline_access","microprofile-jwt"],"access":{"view":true,"configure":true,"manage":true}}, ...]


# client 생성
create_client() {

    curl -k -s -X POST "$KEYCLOAK_URL/admin/realms/$1/clients" \
    -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "'$2'",
        "redirectUris": [
        "'$3'"
        ]
    }'
}
#[{"id":"a28f2629-76d5-40ce-8342-0abb16c31c7c","clientId":"account","name":"${client_account}","rootUrl":"${authBaseUrl}","baseUrl":"/realms/minions/account/","surrogateAuthRequired":false,"enabled":true,"alwaysDisplayInConsole":false,"clientAuthenticatorType":"client-secret","redirectUris":["/realms/minions/account/*"],"webOrigins":[],"notBefore":0,"bearerOnly":false,"consentRequired":false,"standardFlowEnabled":true,"implicitFlowEnabled":false,"directAccessGrantsEnabled":false,"serviceAccountsEnabled":false,"publicClient":true,"frontchannelLogout":false,"protocol":"openid-connect","attributes":{"post.logout.redirect.uris":"+"},"authenticationFlowBindingOverrides":{},"fullScopeAllowed":false,"nodeReRegistrationTimeout":0,"defaultClientScopes":["web-origins","acr","profile","roles","email"],"optionalClientScopes":["address","phone","offline_access","microprofile-jwt"],"access":{"view":true,"configure":true,"manage":true}}, ...]


# Google과 같은 keycloak에서 제공하는 소셜로그인 설정
create_social_idp(){
  curl -k -X POST "$KEYCLOAK_URL/admin/realms/$1/identity-provider/instances" \
  -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "alias": "'$2'",
    "displayName": "'$2'",
    "providerId": "'$2'",
    "enabled": true,
    "updateProfileFirstLoginMode": "on",
    "trustEmail": false,
    "storeToken": true,
    "addReadTokenRoleOnCreate": false,
    "authenticateByDefault": false,
    "linkOnly": false,
    "firstBrokerLoginFlowAlias": "first broker login",
    "config": {
      "clientId": "'$3'",
      "clientSecret": "'$4'",
      "defaultScope": "email profile",
      "prompt": "",
      "hd": "",
      "uiLocales": "",
      "loginHint": "",
      "includeGrantedScopes": "",
      "disableUserInfo": "",
      "userIp": "",
      "guiOrder": ""
    }
  }'
}

# keycloak에서 제공하지않는 소셜로그인 중 oidc를 이용해 소셜로그인 추가 설정
create_oidc_idp(){
curl -k -X POST "$KEYCLOAK_URL/admin/realms/$1/identity-provider/instances" \
  -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "alias": "'$3'",
    "displayName": "'$3'",
    "providerId": "'$2'",
    "firstBrokerLoginFlowAlias": "first broker login",
    "config": {
      "clientId": "'$4'",
      "clientSecret": "'$5'",
      "authorizationUrl": "'$6'",
      "tokenUrl": "'$7'",
      "defaultScope": ""
    }
  }'
}

# Subcommand to add a new realm
init_command() {
    echo "(URL 예시) https://sdevtest.genians.kr:30001"
    read -p "KEYCLOAK_URL을 입력하세요: " KEYCLOAK_URL
    read -p "관리자 로그인을 위한 아이디를 입력하세요: " ADMIN_USERNAME
    read -p "관리자 로그인을 위한 비밀번호를 입력하세요: " -s ADMIN_PASSWORD

}

# realm_client_command() {
#     read -p "무엇을 생성하시겠습니까? (realm or client): " create_option

#     if [ "$create_option" == "realm" ]; then
#         read -p "새로 생성할 realm 이름을 입력하세요: " REALM
#         create_realm "$REALM"
#     elif [ "$create_option" == "client" ]; then
#         read -p "client를 생성할 realm 이름을 입력하세요: " REALM
#         create_client "$REALM"
#     else
#         echo "유효한 선택이 아닙니다. realm 또는 클라이언트 중 하나를 선택하세요."
#         exit 1
#     fi
# }

realm_command() {

    read -p "새로 생성할 Realm 이름을 입력하세요: " REALM
    
    if [ "x$REALM" = "x" ]; then
        echo "[ERROR] Realm 이름을 작성하지 않아 생성하지 못했습니다." >&2
        exit 1
    fi

    get_admin_access_token
    create_realm $REALM


}
client_command() {

    read -p "어떤 Realm에서 Client를 생성하시겠습니까?: " REALM
    
    if [ "x$REALM" = "x" ]; then
        echo "[ERROR] Realm 이름을 작성하지 않아 생성하지 못했습니다." >&2
        exit 1
    fi

    get_admin_access_token
    
    echo -n "클라이언트 리스트 : " 
    get_client_list


    read -p "생성할 Client 이름을 입력하세요 : " CLIENT_ID

    if [ "x$CLIENT_ID" = "x" ]; then
        echo "[ERROR] Client 이름을 작성하지 않아 생성하지 못했습니다." >&2
        exit 1
    fi

    read -p "로그인 성공 시 전환될 페이지 URL를 입력해주세요.: " REDIRECT_URI



    get_admin_access_token
    create_client $REALM $CLIENT_ID $REDIRECT_URI

    echo -n "클라이언트 리스트 : " 
    get_client_list

}


social_login_command() {

    read -p "어떤 Realm에서 social login을 설정하시겠습니까?: " REALM
    
    if [ "x$REALM" = "x" ]; then
        echo "[ERROR] Realm 이름을 작성하지 않아 생성하지 못했습니다." >&2
        exit 1
    fi

    # 제공 idp list, 그외 oidc
    echo "(info) 제공되는 social idp 종류: google"
    echo "(info) 그 외 사용자 정의 방식(oidc를 제공하는 소셜로그인): oidc"
    read -p "설정할 소셜로그인 종류를 고르세요.: " IDP

    if [ "$IDP" = "google" ]; then
        # 사용자가 "google"을 선택한 경우 Google IDP 설정
        read -p "발급받은 Client ID를 입력하세요.: " SOCIAL_CLIENT_ID
        read -p "발급받은 Client Secret을 입력하세요.: " SOCIAL_CLIENT_SECRET

        get_admin_access_token
        create_social_idp $REALM $IDP $SOCIAL_CLIENT_ID $SOCIAL_CLIENT_SECRET

    elif [ "$IDP" = "oidc" ]; then
        # 사용자가 "oidc"를 선택한 경우 OIDC IDP 설정
        read -p "사용자 정의로 설정할 소셜로그인 이름을 작성하세요.: " OIDC_CLIENT_NAME
        read -p "발급받은 Client ID를 입력하세요.: " OIDC_CLIENT_ID
        read -p "발급받은 Client Secret을 입력하세요.: " OIDC_CLIENT_SECRET
        read -p "소셜로그인 Authorization Url을 입력하세요: " OIDC_AUTHORIZATION_URL
        read -p "소셜로그인 Token Url을 입력하세요.: " OIDC_TOKEN_URL
        get_admin_access_token
        create_oidc_idp $REALM $IDP $OIDC_CLIENT_NAME $OIDC_CLIENT_ID $OIDC_CLIENT_SECRET $OIDC_AUTHORIZATION_URL $OIDC_TOKEN_URL

    else
        echo "올바르지 않은 IDP를 선택하셨습니다."
    fi
    

    # if [ "x$REALM" = "x" || "x$IDP_SOCIAL_ID" = "x" || "x$IDP_SOCIAL_SECRET" = "x"]; then
    #     echo "[ERROR] empty" >&2
    #     exit 1
    # fi

}


# Main menu
while true; do
    echo
    echo "--------------------------"
    echo "KEYCLOAK SETTING"
    echo "--------------------------"
    echo "1. [필수] 초기 설정"
    echo "2. realm 설정"
    echo "3. client 설정"
    echo "4. social login 설정"
    #   echo "5. user 설정"
    #   echo "6. user 로그인 테스트"
    echo "0. [종료]"
    echo "--------------------------"
    echo -n "=> 숫자를 입력하세요: "
    read choice
    echo


    case $choice in
        1)
        echo "[초기 설정]"
        init_command
        echo
        ;;
        2)
        echo "[realm 설정]"
        realm_command
        echo
        ;;
        3)
        echo "[client 설정]"
        client_command
        echo
        ;;
        4)
        echo "[social login 설정]"
        social_login_command
        echo
        ;;
        # 4)
        # echo "[user 설정]"

        # echo
        # ;;
        # 5)
        # echo "[user 로그인 테스트]"

        # echo
        # ;;
        0)
        echo "Exiting..."
        exit 0
        ;;
        *)
        echo "잘못선택하셨습니다. 0부터 4까지의 옵션을 설정하세요.."
        ;;
    esac
done

