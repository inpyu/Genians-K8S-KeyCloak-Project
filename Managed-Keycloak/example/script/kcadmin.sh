#!/bin/bash

ADMIN_CONF=kcadmin.conf
source $ADMIN_CONF

# Define the help function
help() {
  echo "Usage: $0 [command]"
  echo
  echo "Commands:"
  echo "  initsdp     Create realm and client to Keycloak"
  echo "  cert        Create Keycloak cert"
  echo "  clientcert  Create Client cert to access Keycloak"
  echo "  adduser     Add a new user to Keycloak"
  echo "  login       Request an access token from Keycloak"
  echo "  userlist    List users in a Keycloak realm"
  echo
}

# Function to request access token from Keycloak
get_access_token() {
  curl -s -q -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$1" \
    -d "username=$2" \
    -d "password=$3" \
    --cert $CLIENT_CERT \
    --key $CLIENT_KEY \
    "$KEYCLOAK_URL/realms/$4/protocol/openid-connect/token" | jq -r '.access_token'
}

# Function to request access token from Keycloak
get_client_access_token() {
  curl -s -q -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password" \
    -d "client_id=$1" \
    -d "client_secret=$2" \
    -d "username=$3" \
    -d "password=$4" \
    --cert $CLIENT_CERT \
    --key $CLIENT_KEY \
    "$KEYCLOAK_URL/realms/$5/protocol/openid-connect/token" | jq -r '.access_token'
}

# Function to create a new realm
create_realm() {
  # Get the response code from the curl command
  RESPONSE_CODE=$(curl -s --location --request POST "$KEYCLOAK_URL/admin/realms" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --cert $CLIENT_CERT \
    --key $CLIENT_KEY \
    --data-raw "{
      \"realm\": \"$1\",
      \"enabled\": true,
      \"displayName\": \"$1\"
    }" -o /dev/null -w "%{http_code}")

  # If the response code is not 201, print the error message and exit if not 409
  if [ "$RESPONSE_CODE" != "201" ]; then
    # Exit the script if the response code is not 409
    if [ "$RESPONSE_CODE" != "409" ]; then
      echo "Failed to create realm: $RESPONSE_CODE"
      exit 1
    else
      echo "Realm already exists"
    fi
  else
    # If the response code is 201, print the success message
    echo "Realm created successfully"
  fi
}

# Function to create a new client in a realm
create_client() {
  REALM="$1"
  read -p "Enter the client_id: " CLIENT_ID

  if [ "x$CLIENT_ID" = "x" ]; then
    echo "[ERROR] Failed to create client: client_id is empty" >&2
    exit 1
  fi

  # Get the response code from the curl command
  RESPONSE_CODE=$(curl -s --location --request POST "$KEYCLOAK_URL/admin/realms/$REALM/clients" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --cert $CLIENT_CERT \
    --key $CLIENT_KEY \
    --data-raw "{
      \"clientId\": \"$CLIENT_ID\",
      \"enabled\": true
    }" -o /dev/null -w "%{http_code}")

  # If the response code is not 201, print the error message and exit if not 409
  if [ "$RESPONSE_CODE" != "201" ]; then
    # Exit the script if the response code is not 409
    if [ "$RESPONSE_CODE" != "409" ]; then
      echo "Failed to create client: $RESPONSE_CODE"
      exit 1
    else
      echo "Client already exists in realm $REALM"
    fi
  else
    # If the response code is 201, print the success message
    echo "Client created successfully in realm $REALM"
  fi

  CLIENT_SECRET=$(get_secret $REALM $CLIENT_ID)
  echo "Client Secret: $CLIENT_SECRET"
}

# Function to create a new user
create_user() {
  # Get the response code from the curl command
  RESPONSE_CODE=$(curl -s --location --request POST "$KEYCLOAK_URL/admin/realms/$REALM/users" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --cert $CLIENT_CERT \
  --key $CLIENT_KEY \
  --data-raw "{
    \"username\": \"$USERNAME\",
    \"email\": \"\",
    \"enabled\": true,
    \"firstName\": \"\",
    \"lastName\": \"\"
  }" -o /dev/null -w "%{http_code}")
  
  # If the response code is not 201, print the error message and exit if not 409
  if [ "$RESPONSE_CODE" != "201" ]; then
    # Exit the script if the response code is not 409
    if [ "$RESPONSE_CODE" != "409" ]; then
      echo "Failed to create user: $RESPONSE_CODE"
      exit 1
    else
      echo "User already exists"
    fi
  else
  # If the response code is 201, print the success message
    echo "User created successfully"
  fi
}

# Function to get the user's ID
get_userid() {
  USER=$(curl -s --location --request GET "$KEYCLOAK_URL/admin/realms/$REALM/users?username=$USERNAME" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --cert $CLIENT_CERT \
  --key $CLIENT_KEY)

  USER_ID=$(echo $USER | jq -r '.[] | .id')
  echo $USER_ID
}

# Function to set user's password
set_user_password() {
  USER_ID=$(get_userid)
  
   # Get the response code from the curl command
   RESPONSE_CODE=$(curl -s --location --request PUT "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID/reset-password" \
   --header 'Content-Type: application/json' \
   --header "Authorization: Bearer $ACCESS_TOKEN" \
  --cert $CLIENT_CERT \
  --key $CLIENT_KEY \
   --data-raw "{
     \"type\": \"password\",
     \"value\": \"$PASSWORD\",
     \"temporary\": false
   }" -o /dev/null -w "%{http_code}")
  
   # If the response code is not 204 or null, print the error message and exit
   if [ "$RESPONSE_CODE" != "204" ] && [ "$RESPONSE_CODE" != "null" ]; then
     echo "Failed to set user password: $RESPONSE_CODE"
     exit 1
   fi

   # Otherwise, print the success message
   echo "User password set successfully"
}

# Function to set user's attribute
set_user_attribute() {

  UUID=$1

   # Get the response code from the curl command
   RESPONSE_CODE=$(curl -s --location --request PUT "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID" \
   --header 'Content-Type: application/json' \
   --header "Authorization: Bearer $ACCESS_TOKEN" \
  --cert $CLIENT_CERT \
  --key $CLIENT_KEY \
   --data-raw "{
     \"attributes\": {
       \"MID\": \"$UUID\"
     }
   }" -o /dev/null -w "%{http_code}")

   # If the response code is not 204 or null, print the error message and exit
   if [ "$RESPONSE_CODE" != "204" ] && [ "$RESPONSE_CODE" != "null" ]; then
     echo "Failed to set user attribute: $RESPONSE_CODE"
     exit 1
   fi
   
   # Otherwise, print the success message
   echo "User attribute set successfully"
}

print_userinfo() {
  USER_INFO=$(curl -s --location --request GET "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --cert $CLIENT_CERT \
  --key $CLIENT_KEY)

  # Print user information
  echo "User information:"
  echo $USER_INFO | jq '{id, createdTimestamp, username, attributes: .attributes.MID}'
}

# Function to decode and verify JWT
decode_jwt() {
  local jwt="$1"

  if command -v jwt-decode &> /dev/null; then
    echo "Header:"
    jwt-decode.header "$jwt"
    echo
    echo "Payload:"
    jwt-decode.payload "$jwt"
  else
    header=$(echo "$jwt" | cut -d'.' -f1 | base64 -d)
    payload=$(echo "$jwt" | cut -d'.' -f2 | base64 -d)

    echo "Header: $header"
    echo "Payload: $payload"
  fi
}

# Subcommand to add a new user
add_user_command() {

  read -p "Enter the username: " USERNAME
  read -p "Enter the password: " -s PASSWORD
  echo

  read -p "Enter the machineid (optional): " MACHINEID
  echo

  if [ "x$USERNAME" = "x" ] || [ "x$PASSWORD" = "x" ]; then
    echo "[ERROR] Failed to create user: username or password is empty" >&2
    exit 1
  fi

  [ "x$MACHINEID" = "x" ] && MACHINEID=$(uuidgen)

  # Request an access token
  ACCESS_TOKEN=$(get_access_token $ADMIN_CLIENT_ID $ADMIN_USERNAME $ADMIN_PASSWORD $ADMIN_REALM)

  # Create a new user
  create_user

  # Set the user's password
  set_user_password

  # Set the user's attribute
  set_user_attribute $MACHINEID

  # Print user information
  print_userinfo

  create_client_cert_command $USERNAME

  redis-cli -h localhost -p 6379 SADD MachineIDs $MACHINEID
}

# Subcommand to add a new realm
init_sdp_command() {

  read -p "Enter the realm: " REALM

  if [ "x$REALM" = "x" ]; then
    echo "[ERROR] Failed to create realm: realm is empty" >&2
    exit 1
  fi

  # Request an access token
  ACCESS_TOKEN=$(get_access_token $ADMIN_CLIENT_ID $ADMIN_USERNAME $ADMIN_PASSWORD $ADMIN_REALM)

  # Create a new user
  create_realm $REALM

  create_client $REALM
}

# Subcommand to add a new user
login_command() {
  read -p "Enter the username: " USERNAME
  read -p "Enter the password: " -s PASSWORD
  echo

  CLIENT_SECRET=$(get_secret $REALM $CLIENT_ID)

  # Request an access token
  ACCESS_TOKEN=$(get_client_access_token $CLIENT_ID $CLIENT_SECRET $USERNAME $PASSWORD $REALM)

  decode_jwt $ACCESS_TOKEN
}

# Subcommand to add a new user
get_secret() {

  # Request an access token
  ACCESS_TOKEN=$(get_access_token $ADMIN_CLIENT_ID $ADMIN_USERNAME $ADMIN_PASSWORD $ADMIN_REALM)

  CLIENT_SECRET=$(curl -s --location --request GET "$KEYCLOAK_URL/admin/realms/$1/clients?clientId=$2" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --cert $CLIENT_CERT \
  --key $CLIENT_KEY | jq -r '.[0].secret')

  echo $CLIENT_SECRET
}

create_cert_command() {

  mkdir -p $CERT_DIR

  if [ ! -f $CA_CERT ] || [ ! -f $CA_KEY ]; then
    echo "Trust CA does not exit. Copy sevpn.cer, sevpn.key to $PWD/cert directory first."
    exit 1
  else
    sudo cp $CA_CERT /usr/local/share/ca-certificates/ztna.crt
    sudo update-ca-certificates
  fi

  echo
  echo "Generating Keycloak server certificate"
  read -p "Enter the DNS: " DNS
  echo

  openssl genrsa -out $KC_CERT_KEY 2048

  openssl req -new -key $KC_CERT_KEY -out $KC_CERT_CSR -subj "/O=Genians/CN=NSR"
>$KC_CERT_EXT cat <<-EOF
authorityKeyIdentifier=keyid,issuer
extendedKeyUsage=serverAuth
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DNS
EOF

  openssl x509 -req -days 3650 -in $KC_CERT_CSR -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out $KC_CERT -extfile $KC_CERT_EXT

  openssl pkcs12 -export -out $CA_P12 -inkey $CA_KEY -in $CA_CERT  -password pass:$PW_P12

  chmod +r $CERT_DIR/*

  # default client cert for keycloak mtls
  create_client_cert_command
}

create_client_cert_command() {

  USERNAME=$1
  CERT_FILE_DIR=

  if [ "x$USERNAME" = "x" ]; then
    CERT_FILE_DIR=$CERT_DIR
    USERNAME=client
  else
    CERT_FILE_DIR=$CERT_USER_DIR/$USERNAME

    # cert 하위에 사용자 이름 디렉토리를 만듭니다.
    mkdir -p $CERT_FILE_DIR
  fi

  openssl genrsa -out $CERT_FILE_DIR/$USERNAME.key 2048

  openssl req -new -key $CERT_FILE_DIR/$USERNAME.key -out $CERT_FILE_DIR/$USERNAME.csr -subj "/O=Genians/CN=$1"
>keycloak.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
EOF

  openssl x509 -req -days 3650 -in $CERT_FILE_DIR/$USERNAME.csr -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out $CERT_FILE_DIR/$USERNAME.crt

  openssl pkcs12 -export -out $CERT_FILE_DIR/$USERNAME.p12 -inkey $CERT_FILE_DIR/$USERNAME.key -in $CERT_FILE_DIR/$USERNAME.crt  -password pass:$PW_P12

  chmod +r $CERT_FILE_DIR
}

# Subcommand to list users in a realm
list_users_command() {
  read -p "Enter the realm: " REALM

  if [ "x$REALM" = "x" ]; then
    echo "[ERROR] Failed to list users: realm is empty" >&2
    exit 1
  fi

  # Request an access token
  ACCESS_TOKEN=$(get_access_token $ADMIN_CLIENT_ID $ADMIN_USERNAME $ADMIN_PASSWORD $ADMIN_REALM)

  # Get the list of users in the specified realm
  USERS=$(curl -s --location --request GET "$KEYCLOAK_URL/admin/realms/$REALM/users" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --cert $CLIENT_CERT \
    --key $CLIENT_KEY)

   # Print the table header
  printf "+----+------------+---------------------------+---------------------------+\n"
  printf "| No | name       | Valid From                | Valid To                  |\n"
  printf "+----+------------+---------------------------+---------------------------+\n"

    # Extract and format the list of usernames
  counter=1
  while IFS= read -r USER; do
    CERT_PATH="$CERT_USER_DIR/$USER/$USER.crt"
    CERT_NOT_BEFORE=$(openssl x509 -noout -in "$CERT_PATH" -startdate | sed 's/notBefore=//')
    CERT_NOT_AFTER=$(openssl x509 -noout -in "$CERT_PATH" -enddate | sed 's/notAfter=//')
    printf "| %-4d | %-10s | %-25s | %-25s |\n" $counter $USER "$CERT_NOT_BEFORE" "$CERT_NOT_AFTER"
    counter=$((counter + 1))
  done < <(echo "$USERS" | jq -r '.[] | .username')

  printf "+----+------------+---------------------------+---------------------------+\n"
}


# Check for subcommand
case "$1" in
  adduser)
    add_user_command
    ;;
  initsdp)
    init_sdp_command
    ;;
  login)
    login_command
    ;;
  cert)
    create_cert_command
    ;;
  clientcert)
    create_client_cert_command
    ;;
  userlist)
    list_users_command
    ;;
  *)
    help
    exit 1
     ;;
esac
