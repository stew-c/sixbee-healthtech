Feature: Authentication

  Scenario: Admin logs in with valid credentials
    When I log in with email "admin@sixbee.co.uk" and password "password123"
    Then the response status is 200
    And the response contains a JWT token
    And the response contains an expiry time

  Scenario: Login fails with wrong password
    When I log in with email "admin@sixbee.co.uk" and password "wrongpassword"
    Then the response status is 401
    And the response contains error "Invalid credentials"

  Scenario: Login fails with non-existent email
    When I log in with email "nobody@example.com" and password "password123"
    Then the response status is 401
    And the response contains error "Invalid credentials"

  Scenario: Login fails with missing email
    When I log in with email "" and password "password123"
    Then the response status is 400

  Scenario: Login fails with missing password
    When I log in with email "admin@sixbee.co.uk" and password ""
    Then the response status is 400

  Scenario: Login endpoint is accessible without authentication
    When I log in with email "admin@sixbee.co.uk" and password "password123"
    Then the request did not require an authorization header
