Feature: /api/users

  @appmap-disable
  Scenario: A user can be created
    When I create a user
    Then the response status should be 201

  Scenario: When a user is created, it should be in the user list
    Given I create a user
    And the response status should be 201
    When I list the users
    Then the response status should be 200
    And the response should include the user
