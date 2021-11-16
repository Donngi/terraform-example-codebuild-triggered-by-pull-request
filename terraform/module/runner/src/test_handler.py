import boto3
import pytest
from botocore.stub import Stubber
from mypy_boto3_dynamodb.service_resource import Table

import handler


# FIXME: Somewhat some errors happen when I define responses as variables. If I directry write values to params,
# error doesn't occur.
# E           botocore.exceptions.ParamValidationError: Parameter validation failed:
# E           Invalid type for parameter Item.repository, value: test-repository, type: <class 'str'>, valid types: <class 'dict'>
#
# response_branch_any_exist = {
#     "Item": {
#         "repository": {"S": "test-repository"},
#         "branch": {"S": "any"},
#     }
# }
# response_branch_test_exist = {
#     "Item": {
#         "repository": {"S": "test-repository"},
#         "branch": {"S": "feature/test"},
#     }
# }
# response_no_item: dict = {}
#
#
# @pytest.mark.parametrize(
#     "dynamodb_get_item_response_branch_any, dynamodb_get_item_response_branch_test, want",
#     [
#         (
#             response_branch_any_exist,
#             response_branch_test_exist,
#             True,
#         ),
#         (
#             response_branch_any_exist,
#             response_no_item,
#             True,
#         ),
#         (
#             response_no_item,
#             response_branch_test_exist,
#             True,
#         ),
#         (
#             response_no_item,
#             response_no_item,
#             False,
#         ),
#     ],
# )
@pytest.mark.parametrize(
    "dynamodb_get_item_response_branch_any, dynamodb_get_item_response_branch_test, want",
    [
        (
            {
                "Item": {
                    "repository": {"S": "test-repository"},
                    "branch": {"S": "any"},
                }
            },
            {
                "Item": {
                    "repository": {"S": "test-repository"},
                    "branch": {"S": "feature/test"},
                }
            },
            False,
        ),
        (
            {
                "Item": {
                    "repository": {"S": "test-repository"},
                    "branch": {"S": "any"},
                }
            },
            {},
            False,
        ),
        (
            {},
            {
                "Item": {
                    "repository": {"S": "test-repository"},
                    "branch": {"S": "feature/test"},
                }
            },
            False,
        ),
        (
            {},
            {},
            True,
        ),
    ],
)
def test_is_needed_to_run_codebuild_project(
    dynamodb_get_item_response_branch_any: dict,
    dynamodb_get_item_response_branch_test: dict,
    want: bool,
) -> None:
    table = boto3.resource("dynamodb").Table("ci-pull-request-deny-list-table")
    stubber = Stubber(table.meta.client)
    stubber.add_response(
        "get_item",
        dynamodb_get_item_response_branch_any,
    )
    stubber.add_response(
        "get_item",
        dynamodb_get_item_response_branch_test,
    )
    stubber.activate()

    got = handler.is_needed_to_run_codebuild_project(table, "test-repository", "feature/test")
    assert got == want
