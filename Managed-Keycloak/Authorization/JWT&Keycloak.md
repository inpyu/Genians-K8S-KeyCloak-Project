# JWT

## **1. JWT(Json Web Token)란?**

---

> **정보를 비밀리에 전달하거나 인증할 때 주로 사용하는 토큰으로, Json객체를 이용함**
> 

- JWT(Json Web Token)란 **Json 포맷을 이용하여 사용자에 대한 속성을 저장하는 Claim 기반의 Web Token**이다. JWT는 토큰 자체를 정보로 사용하는 Self-Contained 방식으로 정보를 안전하게 전달한다. 주로 회원 인증이나 정보 전달에 사용된다.
- JWT는 일반적으로 클라이언트와 서버 사이에서 통신할 때 권한을 위해 사용하는 토큰이다. 웹 상에서 정보를 Json형태로 주고 받기 위해 표준규약에 따라 생성한 암호화된 토큰으로 복잡하고 읽을 수 없는 string 형태로 저장되어있다.




## JWT의 구성요소

---

JWT는 **헤더(header)**, **페이로드(payload)**, **서명(signature)** 세 파트로 나눠져 있다.

1. **Header(헤더):** 토큰 유형을 비롯해 관련된 서명(signature) 알고리즘을 정의한다.
2. **payload(페이로드):** 토큰 자체에 저장되어 전달되는 실제 데이터(claim)를 담고 있다. 
3. **Signature(서명):** 보안 서명을 통해 메시지가 전송 과정에서 바뀌지 않은 것을 확인함.




### **[ JWT 토큰 예시 ]**

아래의 그림은 생성된 JWT의 예시이다.

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/eefe178e-a61b-4434-af94-7230d01f67d1)





### **1. Header(헤더)**

토큰의 헤더는 **typ**과 **alg** 두 가지 정보로 구성된다. alg는 헤더(Header)를 암호화 하는 것이 아니고, **Signature를 해싱하기 위한 알고리즘을 지정**하는 것이다.

- typ: 토큰의 타입을 지정 ex) JWT
- alg: 알고리즘 방식을 지정하며, 서명(Signature) 및 토큰 검증에 사용 ex) **HS256(SHA256) 또는 RSA →** Signature를 해싱하기 위한 알고리즘

```html
{
	 "typ": JWT, 
   "alg": "HS256"
 }
```




### **2. PayLoad(페이로드)**

- 페이로드 부분은 **토큰 자체에 저장되는 실제 데이터(claim)**를 담고 있다.
- 이 정보는 Base64Url 인코딩된 형태로 표현되며, 일반적으로는 JSON 객체의 형태로 구성된다.

클레임은 총 3가지로 나누어지며, Json(Key/Value) 형태로 다수의 정보를 넣을 수 있다.




*2.1 등록된 클레임(Registered Claim)*

등록된 클레임은 토큰 정보를 표현하기 위해 이미 정해진 종류의 데이터들로, 모두 선택적으로 작성이 가능하며 사용할 것을 권장한다. 또한 JWT를 간결하게 하기 위해 key는 모두 길이 3의 String이다. 여기서 subject로는 unique한 값을 사용하는데, 사용자 이메일을 주로 사용한다.

| 클레임 이름 | 의미 | 설명 | 지정 데이터 형식 |
| --- | --- | --- | --- |
| iss | Issuer | JWT 토큰 발급자(서버 측)의 식별자 | 문자열 / String Or URI |
| sub | Subject | JWT의 주어가 되는 주체의 식별자. 토큰 제목 | 문자열 / String Or URI 이 값이 문자열인 경우에는 인증할 client_id여야 한다. |
| aud | Audience | JWT를 이용하는 주체(클라이언트)의 식별자. 토큰 대상자 | 문자열 / String Or URI 값의 배열 ※ 단일도 가능 |
| exp | Expiration Time | 만료 날짜. 기한 이후에 JWT의 처리는 NG. 토큰 만료 시간 | 1970-01-01 00 : 00 : 00Z부터 초 단위로 수치 (IntDate)로 지정 |
| nbf | Not Before | 유효 기간 시작 날짜. 이는 이전에 JWT의 처리는 NG. 토큰 활성 날짜 | 1970-01-01 00 : 00 : 00Z부터 초 단위로 수치 (IntDate)로 지정 |
| iat | Issued At | JWT의 발행 날짜. 토큰 발급 시간 | 1970-01-01 00 : 00 : 00Z부터 초 단위로 수치 (IntDate)로 지정 |
| jti | JWT ID | JWT를 위한 고유 (고유) 식별자. 중복이 일어나지 않도록 지정해야 한다. JWT 토큰 식별자 | 대문자와 소문자를 구별하는 문자열 |
| typ | Type | 콘텐츠 형식의 선언 | 대문자와 소문자를 구별하는 문자열 |

*2.2 공개 클레임(Public Claim)*

공개 클레임은 사용자 정의 클레임으로, 공개용 정보를 위해 사용된다. 충돌 방지를 위해 URI 포맷을 이용하며, 예시는 아래와 같다.

```html
{
    "https://mangkyu.tistory.com": true
}
```




*2.3 비공개 클레임(Private Claim)*

비공개 클레임은 사용자 정의 클레임으로, 서버와 클라이언트 사이에 임의로 지정한 정보를 저장한다. 아래의 예시와 같다.

```html
{
    "token_type": access
}
```




### **3. Signature(서명)**

- 서명(Signature)은 **토큰을 인코딩하거나 유효성 검증을 할 때 사용하는 고유한 암호화 코드**이다.
- 가장 중요한 부분으로 세더와 정보를 합친 후 발급해준 서버가 지정한 SECERET KEY로 암호화 시켜 토큰을 변조하기 어렵게 한다.
    - EX) 토큰 발급 후 누군가가 payload의 정보를 수정할 경우 payload의 정보가 수정될지언정 Signature에는 수정되기 전의 Payload 내용을 기반으로 이미 암호화 되어 있는 결과가 저장되어 있기 때문에 조작되어 있는 Payload와는 다른 결과 값이 나오게 된다.
- 서명(Signature)은 위에서 만든 헤더(Header)와 페이로드(Payload)의 값을 각각 BASE64Url로 인코딩하고, 인코딩한 값을 비밀 키를 이용해 헤더(Header)에서 정의한 알고리즘으로 해싱을 하고, 이 값을 다시 BASE64Url로 인코딩하여 생성한다.

생성된 토큰은 HTTP 통신을 할 때 Authorization이라는 key의 value로 사용된다. 일반적으로 value에는 Bearer이 앞에 붙여진다.

```html
{
    "Authorization": "Bearer {생성된 토큰 값}",
 }
```




### 일반 토큰 기반 vs 클레임 토큰 기반

JWT를 사용하는 가장 큰 이유는 클레임(Claim) 토큰 기반 인증이 주는 편리함이 가장 크다고 할 수 있다. 과연 일반 토큰 기반과 클레임 토큰 기반 인증의 차이는 무엇일까?

기존에 주로 사용하던 **일반 토큰 기반** 인증은 토큰을 검증할 때 필요한 관련 정보들을 서버에 저장해두고 있었기 때문에 항상 DB에 접근해야만 했었다. 또한 session방식 또한 저장소에 저장해두었던 session ID를 찾아와 검증하는 절차를 가져 다소 번거롭게 느껴지곤 했다.

하지만 **클레임 토큰 기반**으로 이루어진 JWT(Json Web Token)는 사용자 인증에 필요한 모든 정보를 토큰 자체에 담고 있기 때문에 별도의 인증 저장소가 필요없다. 분산 마이크로 서비스 환경에서 중앙 집중식 인증 서버와 데이터베이스에 의존하지 않는 쉬운 인증을 제공하여 일반 토큰 기반 인증에 비해 편리하다고 말할 수 있다.




## JWT 동작 원리

---

```json
+---------+                                +----+
|클라이언트|                                |서버|
+---------+                                +----+

|                                               |
|   1. ID, PW 입력하여 로그인 인증(API 호출)     |
|---------------------------------------------->|
|                                               |

|                                               |
|   2,3. 서버에서JWT 토큰 생성 후 전달            |
|<----------------------------------------------|
|                                               |

|                                               |
|   4. API 호출시 JWT TOKEN도 전송               |
|---------------------------------------------->|
|                                               |

|                                               |
|   5. JWT 검증 후 이상 없을 경우 반환함.         |
|<----------------------------------------------|
|                                               |
```

→ 이렇게 간편하게 설명할 수도 있다. 




****[상세 설명]****

![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/9cc2aa25-96a9-459e-a865-28d543b61b26)


1. 사용자가 id와 password를 입력하여 로그인 요청을 한다.
2. 서버는 회원DB에 들어가 있는 사용자인지 확인을 한다.
3. 확인이 되면 서버는 로그인 요청 확인 후, secret key를 통해 토큰을 발급한다.
4. 이것을 클라이언트에 전달한다.
5. 서비스 요청과 권한을 확인하기 위해서 헤더에 데이터(JWT) 요청을 한다.
6. 데이터를 확인하고 JWT에서 사용자 정보를 확인한다.
7. 클라이언트 요청에 대한 응답과 요청한 데이터를 전달해준다.

정말 간단하게 설명해보자면, 아래와 같다.

> 클라이언트가 서버에게 ID, PWD를 보내면 서버가 JWT Token을 발급해준다. 클라이언트는 서버에게 ID, PWD 를 보낼 필요가 없어진다. 앞으로 자동 로그인 api 를 호출시에 JWT 를 보낸다. 그러면 서버는 클라이언트로부터 JWT를 가지고 복구화 작업을 한다.
> 




## JWT 장단점

---

********장점********

- *토큰 자체에 사용자 인증에 필요한 모든 정보가 있기 때문에 별도의 인증 저장소가 필요없음*
- *쿠키를 사용하지 않으므로 쿠키 취약점이 사라짐(클라이언트 정보를 서버가 저장하지 않음)*
- *서버에 부담이 적음*

******단점******

- *정보가 많아 질수록 토큰의 길이가 늘어남으로 네트워크에 부하를 줄수가 있음 -->*
    - *쿠키, 세션과는 다르게 base64 인코딩을 통해 정보 전달을 하므로*
- *payload를 탈취하여 디코딩 하면 데이터를 볼수 있음 -> payload에는 비민감정보만 기입*
- *stateless 하기 때문에 한번 만들어지면 제어가 불가*
    - JWT는 상태를 저장하지 않기 때문에 한번 만들어지면 제어가 불가능하다. 즉, 토큰을 임의로 삭제하는 것이 불가능하므로 토큰 만료 시간을 꼭 넣어주어야 한다.
    




## JWT - **Access Token / Refresh Token**

---

장단점에서 보았듯이 JWT도 제 3자에게 토큰 탈취의 위험성이 있기 때문에, 그대로 사용하는것이 아닌 Access Token, Refresh Token 으로 이중으로 나누어 인증을 하는 방식이 좋다.

Access Token 과 Refresh Token은 둘 다 똑같은 JWT이다. 다만 토큰이 어디에 저장되고 관리되느냐에 따른 사용 차이일 뿐이다.

- **Access Token** : **클라이언트**가 갖고 있는 실제로 유저의 정보가 담긴 토큰으로, 클라이언트에서 요청이 오면 서버에서 해당 토큰에 있는 정보를 활용하여 사용자 정보에 맞게 응답을 진행
- **Refresh Token**: 새로운 Access Token을 발급해주기 위해 사용하는 토큰으로 짧은 수명을 가지는 Access Token에게 새로운 토큰을 발급해주기 위해 사용. 해당 토큰은 보통 **데이터베이스**에 유저 정보와 같이 기록.

정리하자면, Access Token은 접근에 관여하는 토큰, Refresh Token은 재발급에 관여하는 토큰의 역할로 사용되는 JWT 이라고 말할 수 있다.




# KEYCLOAK의 인가

---

- keycloak의 인가 기능은 Realm, Client, Role, User 등의 개념으로 구성됨.
- Realm은 인증 및 인가의 범위를 나타내며, Client는 keycloak에 의해 보호되는 애플리케이션을, user는 keycloak에 등록된 사용자를 나타낸다.
- keycloak 내부에서 client의 Credentials를 보면 secret key를 확인할 수 있음.




## Authorization code 인증

- 사용자가 로그인(인증)을 하면 `Access token`과 `Refresh token`을 발급하고, 이 Access token을 갖고 여러 자원에 접근하는 방식
- OAuth2 표준을 이용한다




## Keycloak 엔드포인트

---

keycloak을 포함한 모든 인증 서버들은 OAuth2 표준을 기반으로 만들어진다. 그리고 OAuth2에 필요한 기능들이 API 형태로 제공된다.




### 1) Realm 생성




### 2) 엔드포인트 목록

realm 생성 후 realm setting에 접속하여 openID Endpoint Configuration을 들어가 중요한 것들을 짚어보려 한다.
![image](https://github.com/sfreet/Managed-Keycloak/assets/120535813/3521e978-9b2c-4788-ac9c-a076fe06fa81)





### 3) issuer

```
{base url}/realms/{realm name}
```

Issuer 는 해당 Realm을 가리키는 url이라고 보면 된다. 하위 경로들은 대부분 정해진 규칙대로 비슷하게 형성되므로, 이 url만 알면 해당 Realm을 통해서 인증/인가 처리를 할 수 있다.

실제로 Spring security를 사용할 때에도 설정파일에 issuer url만 추가해주면 OAuth2기능들이 동작한다.




### 4) authorization_endpoint

```
{base url}/realms/{realm name}/protocol/openid-connect/auth
```

이 엔드포인트는 말 그대로 `인증`을 받는 URL이다.

이 url은 필수적으로 아래의 파라미터들을 기본적으로 포함해야 정상적인 접근이 가능하다.

- response_type: 인증에 성공했을 때, 어떤 값을 응답값으로 받을 것인지
- client_id: 인증절차를 거칠 Realm에 생성된 클라이언트의 id
- redirect_uri: 인증에 성공한 후, redirect될 url
- scope: 인증을 통해서 조회할 데이터의 범위를 설정




### 5) token_endpoint

```
{base url}/realms/{realm name}/protocol/openid-connect/token
```

Access token과 Refresh token을 수령하는 url이다. 위에서 받은 `code`를 이 엔드포인트로 넘겨주면, 해당 사용자에 맞는 토큰들을 응답해준다.




### 6) userinfo_endpoint


```
{base url}/realms/{realm name}/protocol/openid-connect/userinfo
```

위에서 받은 `Access token`을 헤더에 실어서 이 url에 요청하면, Access token에 해당하는 user의 정보를 응답해준다.




### 그 외

위에서 살표본 엔드포인트들이 `Authorization code`형식으로 인증을 받기위한 최소한의 엔드포인트들이다.
