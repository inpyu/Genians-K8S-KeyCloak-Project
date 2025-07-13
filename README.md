# 🔐 Genians팀 ZTNA 인증 서비스 개발 (S개발자 1기)

이 프로젝트는 Genians에서 운영하는 Kubernetes 클러스터 위에 Keycloak을 배포하고, JWT 및 OAuth 기반의 인증·인가 시스템을 구현한 ZTNA(Zero Trust Network Access) 솔루션입니다.

---

## 📁 Repository Structure

```

├── keycloak-k8s              # Keycloak의 K8s 배포 및 커스터마이징 구성
│   ├── certs                 # TLS/SSL 인증서
│   ├── charts                # Helm 차트 (미사용 시 삭제 예정)
│   ├── custom-providers      # 사용자 정의 Keycloak provider
│   ├── data                  # Keycloak 초기화 데이터
│   ├── helmTest              # Helm 테스트용 리소스
│   ├── kcdata                # Keycloak 사용자 및 Realm 설정
│   ├── keycloak-pack         # Keycloak 빌드/배포 패키지
│   ├── shell-script          # 자동화 배포 스크립트
│   ├── docker-compose.yaml   # 로컬 테스트용 도커 컴포즈 파일
│   ├── Dockerfile            # Keycloak 커스터마이징용 도커파일
│   ├── ingress.yaml          # K8s 인그레스 설정
│   ├── keycloak.yaml         # Keycloak 배포 리소스 정의
│   ├── kc-pvc.yaml           # Keycloak PVC 설정
│   ├── mysql.yaml            # MySQL 배포 리소스 정의
│   ├── mysql-pvc.yaml        # MySQL PVC 설정
│   ├── mysql-secret.yaml     # MySQL 보안 정보 설정
│
├── Managed-Keycloak          # 인증/인가 로직 및 Keycloak 연동 모듈
│   ├── Authentication        # 사용자 인증 모듈
│   ├── Authorization         # Keycloak 기반 인가 처리
│   │   └── nginx\_module      # Nginx 연동 및 인증/인가 웹페이지
│   │       ├── \*.html        # 로그인/로그아웃/리디렉션 페이지
│   │       ├── nginx.conf    # Nginx Reverse Proxy 설정
│   │       ├── docker-compose.yml
│   │       └── \*.md          # JWT, Keycloak 기반 인증 설명 문서
│   ├── example               # 예제 구성
│   ├── k8s                   # Kubernetes 관련 리소스 (공통 모듈)
│   ├── plugins               # Keycloak 플러그인
│   ├── scripts               # 배포 및 초기화 스크립트
│   └── README.md             # 서브 시스템 설명 문서

````

---

## 🛠️ 담당 역할 및 구현 내용

### 📌 담당 영역: `keycloak-k8s`

- Genians 사내 K8S 클러스터 상에 Keycloak을 배포 및 관리
- Helm 없이 YAML 및 커스텀 스크립트를 통한 Keycloak 설치 자동화
- MySQL 연동, PVC 설정, Secret 관리 등 완전한 스테이트풀 구성 제공
- Ingress를 통한 외부 접근 및 인증서 기반 TLS 암호화 적용
- `custom-providers/` 디렉토리에서 사용자 정의 Provider 개발 가능
- 로컬 테스트를 위한 `docker-compose.yaml` 구성 병행

### 🔐 통합 인증 흐름

- **Managed-Keycloak** 레포지토리의 `Authentication`, `Authorization` 모듈과 연동
- JWT 기반 세션 발급 및 NGINX 리버스 프록시에서의 인증처리
- Keycloak Realm 및 Client 설정 자동화 스크립트 적용
- `nginx_module` 하위의 커스텀 HTML 페이지를 통한 사용자 경험 향상

---

## 🚀 배포 방법 (요약)

1. MySQL, Secret, PVC 등 설정 리소스 적용
```bash
   kubectl apply -f mysql.yaml
   kubectl apply -f mysql-secret.yaml
   kubectl apply -f mysql-pvc.yaml
```

2. Keycloak 구성 요소 배포
 ```bash
   kubectl apply -f kc-pvc.yaml
   kubectl apply -f keycloak.yaml
 ```

3. Ingress 설정 적용

   ```bash
   kubectl apply -f ingress.yaml
   ```

4. 배포 완료 후 Ingress 주소 또는 LoadBalancer를 통해 접속

---

## 📌 참고사항

* 운영환경은 Genians 사내 Kubernetes 클러스터를 기반으로 구성되었습니다.
* 본 프로젝트는 Zero Trust 아키텍처 하에서 인증을 Keycloak으로 통합하여 보안성을 강화하는 것을 목표로 합니다.
* 내부 인증 시스템과의 연동을 위해 별도의 NGINX 모듈 및 Keycloak 커스터마이징을 병행하였습니다.
