package it.aboutbits;

import java.util.Map;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.jboss.logging.Logger;
import org.keycloak.email.DefaultEmailSenderProvider;
import org.keycloak.email.EmailException;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.RealmProvider;
import org.keycloak.models.UserModel;
import org.keycloak.protocol.oidc.TokenManager;
import org.keycloak.representations.AccessToken;
import org.keycloak.representations.AccessTokenResponse;
import redis.clients.jedis.Jedis;

import java.io.FileWriter;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class CustomEventListenerProvider implements EventListenerProvider {

    private static final Logger log = Logger.getLogger(CustomEventListenerProvider.class);

    private final KeycloakSession session;
    private final RealmProvider model;
    private final String namedPipePath = "/tmp/kc_pipe/auth";

    // KeycloakSession 객체를 받아 초기화하는 생성자
    public CustomEventListenerProvider(KeycloakSession session) {
        this.session = session;
        this.model = session.realms();
    }

    // 이벤트 처리 메서드
    @Override
    public void onEvent(Event event) {
        // 이벤트 타입 확인
        EventType eventType = event.getType();
        
        // 로그인 이벤트인 경우
        if (eventType == EventType.LOGIN) {
            handleLoginEvent(event);
        } 
        // 로그인 실패 이벤트인 경우
        else if (eventType == EventType.LOGIN_ERROR) {
            handleLoginErrorEvent(event);
        } 
        // 로그아웃 이벤트인 경우
        else if (eventType == EventType.LOGOUT) {
            handleLogoutEvent(event);
        }
    }

    // 관리자 이벤트 처리 메서드
    @Override
    public void onEvent(AdminEvent adminEvent, boolean includeRepresentation) {
        // 관리자 이벤트 처리 로직 작성 (필요 시 추가)
    }

    // 리소스 정리 메서드
    @Override
    public void close() {
        // 리소스 정리 로직 작성 (필요 시 추가)
    }

    // 로그인 이벤트 처리 메서드
    private void handleLoginEvent(Event event) {
        // 이벤트에서 사용자 정보 추출
        RealmModel realm = session.realms().getRealm(event.getRealmId());
        UserModel user = session.users().getUserById(realm, event.getUserId());
        String username = user != null ? user.getUsername() : "Unknown User";
        
        // 이벤트에서 IP 주소 추출
        String ipAddress = event.getDetails().get("ipAddress");
        
        // 현재 시간 추출 및 포맷팅
        Date timestamp = new Date(event.getTime());
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String loginTime = dateFormat.format(timestamp);
        
        // 로그 출력
        log.info("사용자: " + username + ", IP 주소: " + ipAddress + "에서 로그인 이벤트 발생 시간: " + loginTime);
    }

    // 로그인 실패 이벤트 처리 메서드
    private void handleLoginErrorEvent(Event event) {
        // 이벤트에서 사용자 정보 추출
        RealmModel realm = session.realms().getRealm(event.getRealmId());
        String username = event.getDetails().get("username");
        
        // 이벤트에서 IP 주소 추출
        String ipAddress = event.getDetails().get("ipAddress");
        
        // 현재 시간 추출 및 포맷팅
        Date timestamp = new Date(event.getTime());
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String loginTime = dateFormat.format(timestamp);
        
        // 로그 출력
        log.error("사용자: " + username + ", IP 주소: " + ipAddress + "에서 로그인 실패 이벤트 발생 시간: " + loginTime + " (렘: " + realm.getName() + ")");
    }

    // 로그아웃 이벤트 처리 메서드
    private void handleLogoutEvent(Event event) {
        // 이벤트에서 사용자 정보 추출
        RealmModel realm = session.realms().getRealm(event.getRealmId());
        UserModel user = session.users().getUserById(realm, event.getUserId());
        String username = user != null ? user.getUsername() : "Unknown User";
        
        // 이벤트에서 IP 주소 추출
        String ipAddress = event.getDetails().get("ipAddress");
        
        // 현재 시간 추출 및 포맷팅
        Date timestamp = new Date(event.getTime());
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String logoutTime = dateFormat.format(timestamp);
        
        // 로그 출력
        log.info("사용자: " + username + ", IP 주소: " + ipAddress + "에서 로그아웃 이벤트 발생 시간: " + logoutTime);
    }
}
