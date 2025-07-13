package it.aboutbits;

import java.util.Map;

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

    public CustomEventListenerProvider(KeycloakSession session) {
        this.session = session;
        this.model = session.realms();
    }

    @Override
    public void onEvent(Event event) {

        if (event.getType() != EventType.LOGIN) {
            return;
        }

        RealmModel realm = session.realms().getRealm(event.getRealmId());
        UserModel user = session.users().getUserById(realm, event.getUserId());
        String machineID = user.getFirstAttribute("MID");

        Map<String, String> details = event.getDetails();
        String tokenID = details.get("token_id");

        writeDataToNamedPipe(machineID, tokenID);

        log.info("machineID=" + machineID + ", tokenID=" + tokenID);
    }

    @Override
    public void onEvent(AdminEvent adminEvent, boolean b) {

    }

    @Override
    public void close() {

    }

    private void writeDataToNamedPipe(String machineID, String tokenID) {
        try (FileWriter writer = new FileWriter(namedPipePath)) {
            String data = machineID + "," + tokenID;
            writer.write(data);
            writer.flush();
        } catch (IOException e) {
            log.error("Error writing data to named pipe: " + e.getMessage());
        }
    }    
}
