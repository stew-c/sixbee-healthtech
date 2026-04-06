Feature: API Middleware

  Scenario: Health check returns healthy
    When I request the health endpoint
    Then the response status is 200
    And the response contains status "healthy"

  Scenario: Unauthenticated request to protected endpoint returns 401
    When I request appointments without an authorization header
    Then the response status is 401

  Scenario: CORS preflight request returns correct headers
    When I send an OPTIONS request to "/api/appointments" from origin "http://localhost:3000"
    Then the response contains header "Access-Control-Allow-Origin"

  Scenario: Unhandled exception returns 500 with safe error message
    Given the appointment service is configured to throw an exception
    When I request appointments as admin
    Then the response status is 500
    And the response contains error "An unexpected error occurred"
    And the response does not contain a stack trace
