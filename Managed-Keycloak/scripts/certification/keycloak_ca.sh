#!/bin/bash

create_client_cert_command() {
# 개인키 생성
openssl genpkey -algorithm RSA -out "$cert_folder/$domain_name.key"

# 자체 인증서 생성을 위한 config 파일을 작성합니다.
cat > $client_cert_config << EOF
[ req ]
default_bits            = 2048
default_md              = sha1
default_keyfile         = Genian_keycloak-rootca.key
distinguished_name      = req_distinguished_name
extensions              = v3_user
## 인증서 요청시에도 extension 이 들어가면 authorityKeyIdentifier 를 찾지 못해 에러가 나므로 막아둔다.
## req_extensions = v3_user

[ v3_user ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
#authorityKeyIdentifier = keyid,issuer
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
## SSL 용 확장키 필드
extendedKeyUsage = serverAuth,clientAuth
subjectAltName          = @alt_names

[alt_names]
## Subject AltName의 DNSName field 에 SSL Host 의 도메인 이름을 적어준다.
## 멀티 도메인일 경우 *.indienote.com 처럼 쓸 수 있다.
DNS.1   = localhost
IP.1 = 127.0.0.1
IP.2 = 221.151.133.217
## 공인 ip 주소 추가 


[req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = KR
countryName_min                 = 2
countryName_max                 = 2

# 회사명 입력
organizationName              = Organization Name (eg, company)
organizationName_default      = genian_keycloak

# 부서 입력
organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = genian_keycloak SSL

# SSL 서비스할 domain 명 입력
commonName                      = Common Name (eg, your name or your server's hostname)
commonName_default              = sdevtest.genians.kr
commonName_max                  = 64
EOF

# CSR (Certificate Signing Request) 생성
openssl req -new -key "$cert_folder/$domain_name.key" -out "$cert_folder/$domain_name.csr" -config $client_cert_config

# 사설 인증서 생성 (Root CA로 서명)
openssl x509 -req -in "$cert_folder/$domain_name.csr" -CA rootCA.crt -CAkey rootCA.key -out "$cert_folder/$domain_name.crt" -days $days

# 생성된 파일 압축
tar -czvf "$cert_folder/$domain_name.tar.gz" "$cert_folder/$domain_name.crt" "$cert_folder/$domain_name.key" "$cert_folder/$domain_name.csr"

# 사용자에게 알림
echo "인증서 생성이 완료되었습니다. $cert_folder/$domain_name.tar.gz 파일을 사용하세요."
}


create_cert_command() { 
# 인증서 폴더가 없으면, 생성합니다.
mkdir -p $cert_folder

# Root CA 개인키 생성
openssl genpkey -algorithm RSA -out rootCA.key

# Root CA의 자체 서명된 인증서 생성을 위한 config 파일을 작성합니다.
cat > $root_ca_config << EOF
[ req ]
default_bits            = 2048
default_md              = sha1
default_keyfile         = genian_keycloak-rootca.key
distinguished_name      = req_distinguished_name
extensions              = v3_ca
req_extensions          = v3_ca
 
[ v3_ca ]
basicConstraints       = critical, CA:TRUE, pathlen:0
subjectKeyIdentifier   = hash
##authorityKeyIdentifier = keyid:always, issuer:always
keyUsage               = keyCertSign, cRLSign
nsCertType             = sslCA, emailCA, objCA

[req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = KR
countryName_min                 = 2
countryName_max                 = 2

# 회사명 입력
organizationName              = Organization Name (eg, company)
organizationName_default      = genian_keycloak_ms
 
# 부서 입력
#organizationalUnitName          = Organizational Unit Name (eg, section)
#organizationalUnitName_default  = CA Project
 
# SSL 서비스할 domain 명 입력
commonName                      = Common Name (eg, your name or your server's hostname)
commonName_default              = sdevtest.genians.kr
commonName_max                  = 64
EOF

# Root CA의 자체 서명된 인증서 생성
openssl req -new -x509 -key rootCA.key -out rootCA.crt -config $root_ca_config

# Root CA의 인증서를 시스템에 추가 (루트로 신뢰)
sudo cp rootCA.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# 사용자로부터 입력 받을 정보
read -p "도메인 이름 (예: example.com): " domain_name
read -p "발급자 (예: My Company): " issuer
read -p "유효 기간 (일수, 예: 365): " days

create_client_cert_command
}


# 인증서 폴더의 경로를 변수로 저장합니다.
cert_folder=/opt/keycloak/kcdata/tls

# 인증서 생성을 위한 config 파일의 경로를 변수로 저장합니다.
root_ca_config=/opt/keycloak/kcdata/tls/root_ca_config.cnf
client_cert_config=/opt/keycloak/kcdata/tls/client_cert_config.cnf

# 인증서 폴더에 인증서 파일이 있는지 확인합니다.
if [ -f "$cert_folder/genian_keycloak.crt" ] && [ -f "$cert_folder/genian_keycloak.key" ]; then
  # 인증서 파일이 있으면, 메시지를 출력하고 docker-compose up을 실행합니다.
  echo "인증서 파일이 이미 존재합니다."


else
  # 인증서 파일이 없으면, 인증서를 생성할 지 물어봅니다.

  read -p "인증서 파일이 없습니다. 인증서를 생성하시겠습니까? (yes/no): " answer
  # 사용자의 입력에 따라 인증서 생성하는 함수를 호출하거나 종료합니다.
  if [ "$answer" == "yes" ]; then
    create_cert_command
  else
    exit 0
  fi
fi


# keycloak 서버를 올릴 건지 물어봅니다.
read -p "keycloak 서버를 올리시겠습니까? (yes/no): " answer

# 사용자의 입력에 따라 docker-compose up -d를 실행하거나 종료합니다.
if [ "$answer" == "yes" ]; then
  docker-compose up -d
else
  exit 0
fi
