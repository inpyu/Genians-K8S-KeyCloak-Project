package main

import (
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
)

const (
	keycloakURL  = "https://benjamin.genians.kr:30004/realms/benjamin/protocol/openid-connect/token"
	clientID     = "client-benjamin"
	clientSecret = "DNVxxuKoBtjSUEcYEiRYmCIYALn4c6tz"
	username     = "benny"
	password     = "rhkr"
)

func main() {
	// Create the form data for the login request
	data := url.Values{}
	data.Set("grant_type", "password")
	data.Set("client_id", clientID)
	data.Set("client_secret", clientSecret)
	data.Set("username", username)
	data.Set("password", password)

	// Convert the form data to io.Reader
	body := strings.NewReader(data.Encode())

	// Create the HTTP request
	req, err := http.NewRequest("POST", keycloakURL, body)
	if err != nil {
		fmt.Println("Error creating request:", err)
		return
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	/* Keycloak과 mTLS 연결 구현시 아래 코드를 참조해서 구현
	// Load the client certificate and key
	cert, err := tls.LoadX509KeyPair("client.crt", "client.key")
	if err != nil {
		fmt.Println("Error loading certificate and key:", err)
		return
	}

	// Create a TLS config with the certificate
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		InsecureSkipVerify: true, // Skip server certificate verification
	}

	// Create a transport with the TLS config
	tr := &http.Transport{
		TLSClientConfig: tlsConfig,
	}*/

	// Create a custom transport with insecure TLS config
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}

	// Create a client with the custom transport
	client := &http.Client{Transport: tr}

	// Send the request and read the response
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending request:", err)
		return
	}
	defer resp.Body.Close()
	bodyReader, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response:", err)
		return
	}

	// Unmarshal the response body to a map
	var result map[string]interface{}
	err = json.Unmarshal(bodyReader, &result)
	if err != nil {
		fmt.Println("Error unmarshaling response:", err)
		return
	}

	// Check if access_token key exists and is not empty
	token, ok := result["access_token"]
	if !ok || token == "" {
		fmt.Println("Login failed: no access token")
	} else {
		fmt.Println("Login succeeded: access token =", token)
	}

	// Parse the access token to get jti, agw, mid values
	parts := strings.Split(token.(string), ".")
	if len(parts) != 3 {
		fmt.Println("Invalid access token format")
		return
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		fmt.Println("Error decoding payload:", err)
		return
	}
	var claims map[string]interface{}
	err = json.Unmarshal(payload, &claims)
	if err != nil {
		fmt.Println("Error unmarshaling payload:", err)
		return
	}

	// Get the jti, agw, mid values from the claims map
	jti, ok1 := claims["jti"]
	agw, ok2 := claims["agw"]
	mid, ok3 := claims["mid"]
	if !ok1 || !ok2 || !ok3 {
		fmt.Println("Missing jti, agw or mid in payload")
		return
	}

	// Print the jti, agw, mid values as variables
	fmt.Printf("jti = %v\n", jti) // agw 접속시 sdp key
	fmt.Printf("agw = %v\n", agw) // agw ip, port
	fmt.Printf("mid = %v\n", mid) // machineid, 하지만 단말은 이미 이 정보를 가지고 있으므로 사용할 필요없음
}
