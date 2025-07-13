# KEYCLOAK의 인가

---

- keycloak의 인가 기능은 Realm, Client, Role, User 등의 개념으로 구성됨.
- Realm은 인증 및 인가의 범위를 나타내며, Client는 keycloak에 의해 보호되는 애플리케이션을, user는 keycloak에 등록된 사용자를 나타낸다.
- keycloak 내부에서 client의 Credentials를 보면 secret key를 확인할 수 있음.

## Authorization code 인증

- 사용자가 로그인(인증)을 하면 `Access token`과 `Refresh token`을 발급하고, 이 Access token을 갖고 여러 자원에 접근하는 방식
- OAuth2 표준을 이용한다

# keycloak 개념

---

Realm

- 인증, 권한 부여가 적용되는 범위를 나타내는 단위
- SSO로서 인증 대상의 범위를 지정한다라고 생각하면 된다.
- Realm을 통해 Namespace 형태로 관리할 수 있다.
- 다수의 realm을 가질 수 있고 일반적으로 master(default로 생성된 realm)는 관리자의 목적으로만 사용하고 다른 realm을 생성하여 사용하기를 권장한다.

Client

- SSO를 사용할 각 Application
- 하나의 Realm에 n개의 Client를 생성, 관리할 수 있다.

User

- Client에 인증을 요청할 사용자(실제 로그인할 사용자계정)
- 하나의 Realm에는 Realm에 종속된 n개의 User를 생성하고 관리할 수 있다.
- 기본적으로 User는 Username, Email, FirstName, LastName 으로 구성되어 있지만 Custom User Attribute를 사용하면 사용자가 원하는 속성을 추가할 수 있다.

Role

- User에게 부여할 권한 내용
- KeyCloak의 REST API를 사용할 권한을 부여할 수 있고 사용자가 정의한 권한을 부여할 수도 있다.

## Keycloak 엔드포인트

---

keycloak을 포함한 모든 인증 서버들은 OAuth2 표준을 기반으로 만들어진다. 그리고 OAuth2에 필요한 기능들이 API 형태로 제공된다.

# keycloak 설정

---

### 1) Realm 생성

Keycloak은 설치시 기본적으로 Master realm을 제공하지만 다음과 같이 다른 realm을 관리하기 위해 사용하기 때문에 새로운 realm을 생성하여 사용해야 한다.

SSO 적용은 Realm 단위로 한다.

예를 들어, Daum mail을 쓰다가, Daum cafe 서비스에 접속할 때 따로 로그인이 필요 없는건 하나의 Realm으로 묶여 있기 때문인 것이다.

User의 Role을 설정하면 사용자, 관리자 등으로 구분된 권한을 줄 수 있다.

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/2bc4fbf9-d95d-4a02-b232-8945821d5225)



### 1-2) 엔드포인트 목록

realm 생성 후 realm setting에 접속하여 openID Endpoint Configuration을 들어가 중요한 것들을 짚어보려 한다.

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/9aa75658-df0c-4bf4-91d8-e4b8f408717f)


### 1-3) issuer

```
{base url}/realms/{realm name}
```

Issuer 는 해당 Realm을 가리키는 url이라고 보면 된다. 하위 경로들은 대부분 정해진 규칙대로 비슷하게 형성되므로, 이 url만 알면 해당 Realm을 통해서 인증/인가 처리를 할 수 있다.

실제로 Spring security를 사용할 때에도 설정파일에 issuer url만 추가해주면 OAuth2기능들이 동작한다.

### 1-4) authorization_endpoint

```
{base url}/realms/{realm name}/protocol/openid-connect/auth
```

이 엔드포인트는 말 그대로 `인증`을 받는 URL이다.

이 url은 필수적으로 아래의 파라미터들을 기본적으로 포함해야 정상적인 접근이 가능하다.

- response_type: 인증에 성공했을 때, 어떤 값을 응답값으로 받을 것인지
- client_id: 인증절차를 거칠 Realm에 생성된 클라이언트의 id
- redirect_uri: 인증에 성공한 후, redirect될 url
- scope: 인증을 통해서 조회할 데이터의 범위를 설정

### 1-5) token_endpoint

```
{base url}/realms/{realm name}/protocol/openid-connect/token
```

Access token과 Refresh token을 수령하는 url이다. 위에서 받은 `code`를 이 엔드포인트로 넘겨주면, 해당 사용자에 맞는 토큰들을 응답해준다.

### 1-6) userinfo_endpoint

```
{base url}/realms/{realm name}/protocol/openid-connect/userinfo
```

위에서 받은 `Access token`을 헤더에 실어서 이 url에 요청하면, Access token에 해당하는 user의 정보를 응답해준다.

### 그 외

위에서 살표본 엔드포인트들이 `Authorization code`형식으로 인증을 받기위한 최소한의 엔드포인트들이다.

## 2) Client 생성

좌측에서 onfigure > Clients 메뉴로 이동하면 해당 realm에 등록된 client 목록을 확인할 수 있습니다. 우측 상단의 'Create' 버튼을 클릭해준다.

### 2-1) Client 설정

client ID와 관련 setting을 위한 항목들은 다음과 같다.

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/e64ca605-d876-4407-a301-41653e9e85f6)


openID SSO 사용을 위해 설정한 항목들이다. 

- **Standard Flow Enabled:** 인증 코드를 포함한 OIDC redirect 기반의 인증 허용 여부OAuth 2.0 스펙에 따른 인증 코드 흐름을 지원 (Authrization Code Flow)
- **Implicit Flow Enabled:** 인증 코드를 제외한 OIDC redirect 기반의 인증 허용 여부OAuth 2.0 스펙에 따른 암시적인 흐름을 지원 (Implicit Flow)
- **Direct Access Grants Enabled:** 클라이언트의 사용자 username/password 접근 허용 및 변경 가능 여부OAuth 2.0 스펙에 따른 리소스 소유자 자격 증명 부여를 지원 (Resource Owner Password Credential Grant)
- **Service Account Enabled:** 클라이언트의 Keycloak에 인증 및 access token 검색 허용 여부OAuth 2.0 스펙에 따른 자격 증명 부여를 지원 (Client Credential Grant)
- **Authorization Enabled:** 클라이언트별 권한 부여 여부
- **Root URL :** 서비스의 root url
- **Valid Redirect URIs:** 로그인/로그아웃 이후에 브라우저가 redirect하는 uri
- **Admin URL:** 클라이언트의 기본 url
- **Web Origins:** CORS origin을 허용할 uri
- **Backchannel Logout Session Required:** backchannel logout 사용시 logout token에 대한 session id 포함 여부

→ 우리는 이중에서 standard Flow와 Implicit Flow, Direct Access Grants, Service Account, Authorization, Backchanneul Logout 과 관련된 것을 설정해준다.

또한, client 설정에서 Access type을  confidiential로 설정해준다. 그리고 Valid Redirect URLs가 나오는데 보통 해당 클라이언트를 만들 주소를 집어넣는다. 테스트 단계의 경우 *를 넣어서 모든 경로를 설정해줘도 된다.

### 또는,

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/3ff65e76-3a54-463b-814c-236d042f5cbf)

- **Client authentication:** 생성할 클라이언트를 public하게 사용할지 말지를 정한다. 아마 거의 대부분의 경우 public하게 사용하지는 않을 것이므로, 대부분은 이 옵션은 활성화해주면 된다.
- [**Authorization](https://www.keycloak.org/docs/latest/authorization_services/):** 활성화하면, 권한이나 규칙등등 다양한 기준을 통해서 사용자 Autorization(인가)기능을 제공한다.
- **Authentication Flow:** 사용자에게 어떤 인증(로그인)절차를 제공할지 설정한다.

⇒ 해당 것들을 참고하면 괜찮을 듯 하다

- **Redirect URI**

사용자가 인증(로그인)에 성공했을 때, Redirect시킬 수 있는 URI들을 미리 정의해둘 수 있다.

클라이언트가 요청한 Redirect URI가 여기에 미리 정의되어 있어야 그 URI로 Redirect될 수 있다.

이는 당연히 보안을 위해서 상호간에 합의된 URI만 취급하겠다는 의도이다.

또, 이렇게 함으로써 서비스 별로 각자의 Redirect URI를 설정할 수 있게 된다.

위에서 이야기한, 인증/인가만 Keycloak이 해주고 다시 각자의 서비스에서 계속 사용자 경험을 이어갈 수 있는 것이다

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/668cab82-cf64-4858-8c7d-0fbfd7106620)

### 2-2) Role 설정(Client)

해당 Client의 권한(Role) 종류들을 만들 수 있는데 이는 나중에 User를 등록할 때 해당 클라이언트마다의 role mapping을 만들 수 있다. add role을 이용해 role을 만들 수 있으며 스프링과 연동 시에는 Role_{Role 타입} 과 같은 형식으로 만들면 된다.

### 2-3) Group 생성 후 Role Mappings

Role Mappings 탭으로 이동하여 Role을 Mapping함. Client Roles 항목에서 추가한 클라이언트를 선택하고 해당 클라이언트에 설정한 Role을 선택하여 'Add selected' 버튼을 클릭해준.

### 2-4) Credentials - Client secret

클라이언트에 아무나 접근하지 못하도록 해주는 비밀번호임. 이 값이 있어야 사용자는 이 Keycloak의 client와 통신할 수 있다. 가장 핵심적인 보안 장치라고 할 수 있다.

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/394097ff-9ac5-4320-bdce-8f03133c8159)

## 3) User 생성

- 마지막으로 사용자를 추가해준다. 좌측에서 Manage > Users 메뉴로 이동하고 'Add user' 버튼을 클릭해준다.
- 계정의 아이디로 사용될 username을 입력하고 email을 입력해줍니다. Groups 항목에서는 사용자가 속할 그룹을 선택하고 'Save' 버튼을 클릭해줍니다.
    
    Grafana의 경우엔 email을 요구하기 때문에 필수값이 아니더라도 입력해줘야 합니다. 마찬가지로 다른 서비스를 연동하는 경우에도 사용자에 대해 요구하는 필드가 있는지 확인해줘야 합니다.
    

사용자가 추가되면 해당 사용자의 상세 화면에서 Credentials 탭으로 이동합니다. 여기서는 사용자의 비밀번호를 설정해줍니다.
