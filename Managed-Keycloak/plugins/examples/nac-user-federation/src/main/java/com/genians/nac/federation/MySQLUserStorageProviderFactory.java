package com.genians.nac.federation;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;
import org.jboss.logging.Logger;
import org.keycloak.component.ComponentModel;
import org.keycloak.component.ComponentValidationException;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.provider.ProviderConfigProperty;
import org.keycloak.provider.ProviderConfigurationBuilder;
import org.keycloak.storage.UserStorageProviderFactory;

/**
 * User federation 에서 mysql 접속을 위한 DB connection 환경 설정 정보 입력 및 DB connection을 생성하는 로직을 담고 있다.
 * 
 * @author yckim
 */
public class MySQLUserStorageProviderFactory implements UserStorageProviderFactory<MySQLUserStorageProvider> {

    private static final Logger logger = Logger.getLogger(MySQLUserStorageProviderFactory.class);

    protected static final List<ProviderConfigProperty> configMetadata;

    public static final String PROVIDER_NAME = "genian-nac-mysql-users";
    
    private static final String CONFIG_MYSQL = "mysql";
    private static final String CONFIG_DBUSER = "dbuser";
    private static final String CONFIG_DBPASSWORD = "dbpassword";
    private static final String MYSQL_DRIVER_NAME = "com.mysql.cj.jdbc.Driver";

    /**
     * User federation 설정화면에서 보여줄 (입력받을) 폼을 생성한다.
     * mysql connction URI, user, password 정보를 입력받아 사용한다.
     */
    static {
        configMetadata = ProviderConfigurationBuilder.create()
                .property().name(CONFIG_MYSQL)
                .type(ProviderConfigProperty.STRING_TYPE)
                .label("MySQL URI")
                .defaultValue("jdbc:mysql://dbserver/ALDER?autoReconnect=true&useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&jdbcCompliantTruncation=false&useOldAliasMetadataBehavior=true&functionsNeverReturnBlobs=true&useSSL=false").helpText("MySQL URI").add()
                
                .property().name(CONFIG_DBUSER)
                .type(ProviderConfigProperty.STRING_TYPE).label("DB User").defaultValue("root")
                .helpText("DB User").add()
                
                .property().name(CONFIG_DBPASSWORD)
                .type(ProviderConfigProperty.PASSWORD).label("DB Password").defaultValue("")
                .helpText("DB Password").add()
                
                .build();
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return configMetadata;
    }

    @Override
    public String getId() {
        return PROVIDER_NAME;
    }

    /**
     * component를 생성하기 전에 설정값을 validation 한다.
     * @param session
     * @param realm
     * @param model
     * @throws ComponentValidationException 
     */
    @Override
    public void validateConfiguration(KeycloakSession session, RealmModel realm, ComponentModel model)
            throws ComponentValidationException {
        String uri = model.getConfig().getFirst(CONFIG_MYSQL);
        if (uri == null) {
            throw new ComponentValidationException("MySQL connection URI not present");
        }
        
        String dbuser = model.getConfig().getFirst(CONFIG_DBUSER);
        if (dbuser == null) {
            throw new ComponentValidationException("MySQL connection user not present");
        }
        
        String dbpassword = model.getConfig().getFirst(CONFIG_DBPASSWORD);
        if (dbpassword == null) {
            throw new ComponentValidationException("MySQL connection password not present");
        }
        
        Connection conn = null;
        try {
            
            Class.forName(MYSQL_DRIVER_NAME).newInstance();
            conn = DriverManager.getConnection(uri, dbuser, dbpassword);
            conn.isValid(1000);
            
        } catch (SQLException ex) {
            logger.error("SQLException: " + ex.getMessage());
            logger.error("SQLState: " + ex.getSQLState());
            logger.error("VendorError: " + ex.getErrorCode());
            throw new ComponentValidationException(ex.getMessage());
        } catch (ClassNotFoundException | InstantiationException | IllegalAccessException ex) {
            logger.error("", ex);
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                    logger.debug("called DB connection close of provider factory");
                } catch (SQLException ex) {
                    logger.error("", ex);
                }
            }
        }
    }

    /**
     * Keycloak transaction 마다 한번 호출된다.
     * 사용자 로그인이 발생하면 로그인 process가 처리될때 DB connection을 생성한다.
     *
     * @param session
     * @param model
     * @return 
     */
    @Override
    public MySQLUserStorageProvider create(KeycloakSession session, ComponentModel model) {
        String uri = model.getConfig().getFirst(CONFIG_MYSQL);
        String dbuser = model.getConfig().getFirst(CONFIG_DBUSER);
        String dbpassword = model.getConfig().getFirst(CONFIG_DBPASSWORD);

        Connection conn = null;
        try {
            Class.forName(MYSQL_DRIVER_NAME).newInstance();
            conn = DriverManager.getConnection(uri, dbuser, dbpassword);
        } catch (SQLException  ex) {
            logger.error("SQLException: " + ex.getMessage());
            logger.error("SQLState: " + ex.getSQLState());
            logger.error("VendorError: " + ex.getErrorCode());
            throw new ComponentValidationException(ex.getMessage());
        } catch (ClassNotFoundException | InstantiationException | IllegalAccessException ex) {
            logger.error("", ex);
        }

        return new MySQLUserStorageProvider(session, model, conn);
    }
}
