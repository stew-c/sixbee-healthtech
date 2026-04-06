Feature: Appointment Management

  Scenario: Patient submits a booking
    When a patient submits a booking with name "John Smith"
    Then the response status is 201
    And the response contains appointment with name "John Smith"
    And the response contains appointment with status "pending"

  Scenario: Patient submits a booking with missing fields
    When a patient submits a booking with missing name
    Then the response status is 400

  Scenario: Patient submits a booking with past date
    When a patient submits a booking with a past date
    Then the response status is 400

  Scenario: Admin lists appointments with pagination
    Given there are 15 appointments
    When an admin requests page 1 with page size 10
    Then the response status is 200
    And the response contains 10 appointment items
    And the response contains total count 15

  Scenario: Admin edits an appointment
    Given an appointment exists with name "Original Name"
    When an admin updates the appointment name to "Updated Name"
    Then the response status is 200
    And the response contains appointment with name "Updated Name"

  Scenario: Admin approves an appointment
    Given a pending appointment exists
    When an admin approves the appointment
    Then the response status is 200
    And the response contains appointment with status "approved"

  Scenario: Admin deletes an appointment
    Given an appointment exists
    When an admin deletes the appointment
    Then the response status is 204

  Scenario: Unauthenticated request to list appointments is rejected
    When an unauthenticated user requests the appointment list
    Then the response status is 401

