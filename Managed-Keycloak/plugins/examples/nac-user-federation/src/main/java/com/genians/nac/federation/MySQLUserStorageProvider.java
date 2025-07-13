package com.genians.nac.federation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;
import org.jboss.logging.Logger;
import org.keycloak.component.ComponentModel;
import org.keycloak.credential.CredentialInput;
import org.keycloak.credential.CredentialInputUpdater;
import org.keycloak.credential.CredentialInputValidator;
import org.keycloak.credential.LegacyUserCredentialManager;
import org.keycloak.models.CredentialValidationOutput;
import org.keycloak.models.GroupModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.RoleModel;
import org.keycloak.models.SubjectCredentialManager;
import org.keycloak.models.UserModel;
import org.keycloak.models.credential.PasswordCredentialModel;
import org.keycloak.storage.ReadOnlyException;
import org.keycloak.storage.StorageId;
import org.keycloak.storage.UserStorageProvider;
import org.keycloak.storage.adapter.AbstractUserAdapter;
import org.keycloak.storage.user.UserLookupProvider;

/**
 * Keycloak transaction 마다 한번 instance가 생성된다.
 * transaction이 끝나면 close() 메소드가 호출된다.
 * 여기서는 close()메소드에 mysql connection close 로직이 담겨있다.
 * @author yckim
 */
public class MySQLUserStorageProvider
        implements UserStorageProvider, UserLookupProvider, CredentialInputValidator, CredentialInputUpdater {

    protected KeycloakSession session;
    protected Connection conn;
    protected ComponentModel model;
    
    // map of loaded users in this transaction
    protected Map<String, UserModel> loadedUsers = new HashMap<>();
    
    private static final Logger logger = Logger.getLogger(MySQLUserStorageProvider.class);
    
    private final String userPasswordQuery = "SELECT USER_ID, USER_PASSWORD FROM USER WHERE USER_ID = ?;";

    public MySQLUserStorageProvider(KeycloakSession session, ComponentModel model, Connection conn) {
        this.session = session;
        this.model = model;
        this.conn = conn;
    }
    
    
    @Override
    public UserModel getUserByUsername(RealmModel realm, String username) {
        UserModel adapter = loadedUsers.get(username);
        
        if (adapter != null) {
            return adapter;
        }
        
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            pstmt = conn.prepareStatement(userPasswordQuery);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            String password = null;
            if (rs.next()) {
                password = rs.getString("USER_PASSWORD");
            }
            if (password != null) {
                adapter = createAdapter(realm, username);
                loadedUsers.put(username, adapter);
            }
            logger.debug("getUserByUsername()_username: " + username);
        } catch (SQLException ex) {
            logger.error("SQLException: " , ex);
            logger.error("SQLState: " + ex.getSQLState());
            logger.error("VendorError: " + ex.getErrorCode());
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException ex) {
                    logger.error("", ex);
                } 

                rs = null;
            }

            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException ex) {
                    logger.error("", ex);
                } 
                pstmt = null;
            }
        }
        return adapter;
    }

    protected UserModel createAdapter(RealmModel realm, String username) {
        return new AbstractUserAdapter(session, realm, model) {
            @Override
            public String getUsername() {
                return username;
            }

            @Override
            public Stream<GroupModel> getGroupsStream(String search, Integer first, Integer max) {
                return super.getGroupsStream(search, first, max); 
            }

            @Override
            public long getGroupsCount() {
                return super.getGroupsCount(); 
            }

            @Override
            public long getGroupsCountByNameContaining(String search) {
                return super.getGroupsCountByNameContaining(search); 
            }

            @Override
            public SubjectCredentialManager credentialManager() {
                return new LegacyUserCredentialManager(session, realm, this);
            }

            @Override
            public boolean hasDirectRole(RoleModel role) {
                return super.hasDirectRole(role); 
            }
        };
    }

    
    @Override
    public UserModel getUserById(RealmModel realm, String id) {
        StorageId storageId = new StorageId(id);
        String username = storageId.getExternalId();
        return getUserByUsername(realm, username);
    }

    public UserModel getUserByEmail(String email, RealmModel realm) {
        return null;
    }

    @Override
    public boolean isConfiguredFor(RealmModel realm, UserModel user, String credentialType) {
        String password = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            pstmt = conn.prepareStatement(userPasswordQuery);
            pstmt.setString(1, user.getUsername());
            rs = pstmt.executeQuery();
            if (rs.next()) {
                password = rs.getString("USER_PASSWORD");
            }
            logger.debug("isConfiguredFor()_username: " + user.getUsername());
        } catch (SQLException ex) {
            logger.error("SQLException: " , ex);
            logger.error("SQLState: " + ex.getSQLState());
            logger.error("VendorError: " + ex.getErrorCode());
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException ex) {
                    logger.error("",ex);
                } 

                rs = null;
            }

            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException ex) {
                    logger.error("",ex);
                } 

                pstmt = null;
            }
        }
        return credentialType.equals(PasswordCredentialModel.TYPE) && password != null;
    }

    @Override
    public boolean supportsCredentialType(String credentialType) {
        return credentialType.equals(PasswordCredentialModel.TYPE);
    }

    /**
     * 입력된 패스워드가 맞는지 확인한다.
     * @param realm
     * @param user
     * @param input
     * @return 
     */
    @Override
    public boolean isValid(RealmModel realm, UserModel user, CredentialInput input) {
        if (!supportsCredentialType(input.getType()))
            return false;
        String encryptPassword = null;
        String dbStoredPassword = null;
        String passcrypttype = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        
        try {
            String query = "SELECT USER_PASSCRYPTTYPE FROM USER WHERE USER_ID = ?;";
            pstmt = conn.prepareStatement(query);
            pstmt.setString(1, user.getUsername());
            rs = pstmt.executeQuery();
            if (rs.next()) {
                passcrypttype = rs.getString("USER_PASSCRYPTTYPE");
            }
            logger.debug("isValid()_username: " + user.getUsername());
            logger.debug("isValid()_passcrypttype: " + passcrypttype);       
        } catch (SQLException ex) {
            logger.error("SQLException: " , ex);
            logger.error("SQLState: " + ex.getSQLState());
            logger.error("VendorError: " + ex.getErrorCode());
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException ex) {
                } // ignore

                rs = null;
            }

            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException ex) {
                } // ignore

                pstmt = null;
            }
        }
        
        if (passcrypttype == null || passcrypttype.equals("") ) {
            passcrypttype  = "";
        }
        
        String userInputPassword = input.getChallengeResponse();
        
        try {
            String query = "SELECT GETPASS(?,?) ENCRYPTPASS, USER_PASSWORD FROM USER WHERE USER_ID = ?;";
            pstmt = conn.prepareStatement(query);
            pstmt.setString(1, passcrypttype);
            pstmt.setString(2, userInputPassword);
            pstmt.setString(3, user.getUsername());
            rs = pstmt.executeQuery();
            if (rs.next()) {
                encryptPassword = rs.getString("ENCRYPTPASS");
                dbStoredPassword = rs.getString("USER_PASSWORD");
            }
            logger.debug("isValid()_GETPASS_username: " + user.getUsername());
            if (encryptPassword != null && dbStoredPassword != null) {
                logger.debug("isValid()_GETPASS_isEquals: " + encryptPassword.equalsIgnoreCase(dbStoredPassword));
            }
            
        } catch (SQLException ex) {
            logger.error("SQLException: " ,ex);
            logger.error("SQLState: " + ex.getSQLState());
            logger.error("VendorError: " + ex.getErrorCode());
        } finally {

            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException ex) {
                    logger.error("",ex);
                } 

                rs = null;
            }

            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException ex) {
                    logger.error("",ex);
                } 

                pstmt = null;
            }
        }

        if (encryptPassword == null)
            return false;

        
        return encryptPassword.equalsIgnoreCase(dbStoredPassword);
    }

    @Override
    public boolean updateCredential(RealmModel realm, UserModel user, CredentialInput input) {
        if (input.getType().equals(PasswordCredentialModel.TYPE))
            throw new ReadOnlyException("user is read only for this update");

        return false;
    }

    @Override
    public void disableCredentialType(RealmModel realm, UserModel user, String credentialType) {

    }

    public Set<String> getDisableableCredentialTypes(RealmModel realm, UserModel user) {
        return Collections.EMPTY_SET;
    }

    @Override
    public void close() {
        if (conn != null) {
            try {
                conn.close();
                logger.debug("called DB connection close of provider");
            } catch (SQLException ex) {
                logger.error(ex.getMessage());
            } // ignore
            conn = null;
        }
    }

    @Override
    public void preRemove(RealmModel realm) {
        UserStorageProvider.super.preRemove(realm); 
    }

    @Override
    public void preRemove(RealmModel realm, GroupModel group) {
        UserStorageProvider.super.preRemove(realm, group); 
    }

    @Override
    public void preRemove(RealmModel realm, RoleModel role) {
        UserStorageProvider.super.preRemove(realm, role); 
    }


    @Override
    public CredentialValidationOutput getUserByCredential(RealmModel realm, CredentialInput input) {
        return UserLookupProvider.super.getUserByCredential(realm, input); 
    }

    @Override
    public UserModel getUserByEmail(RealmModel realm, String email) {
        throw new UnsupportedOperationException("Not supported yet."); 
    }

    @Override
    public Stream<String> getDisableableCredentialTypesStream(RealmModel realm, UserModel user) {
        throw new UnsupportedOperationException("Not supported yet."); 
    }

}
