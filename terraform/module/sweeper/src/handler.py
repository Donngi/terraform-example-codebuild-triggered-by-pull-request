import os
from logging import getLogger
from typing import Any

import boto3
from mypy_boto3_codebuild import CodeBuildClient
from mypy_boto3_codebuild.type_defs import CreateProjectOutputTypeDef, StartBuildOutputTypeDef
from mypy_boto3_dynamodb.service_resource import Table

logger = getLogger(__name__)
logger.setLevel(os.getenv("LOG_LEVEL", "WARNING"))


def delete_codebuild(client: CodeBuildClient, project_name: str) -> None:
    client.delete_project(name=project_name)


def is_needed_to_delete_codebuild_project(
    table: Table, repository_name: str, branch_name: str
) -> bool:
    res_any = table.get_item(
        Key={"repository": repository_name, "branch": "any"},
    )
    res_branch = table.get_item(
        Key={"repository": repository_name, "branch": branch_name},
    )
    if "Item" in res_any or "Item" in res_branch:
        return False
    return True


def handle_request(event: Any, context: Any) -> None:
    logger.debug(f"event: {event}")

    repository_name = event["detail"]["repositoryNames"][0]
    branch_name = event["detail"]["sourceReference"].replace("refs/heads/", "")
    branch_name_escaped = branch_name.replace("/", "-")
    pull_request_id = event["detail"]["pullRequestId"]
    table_name = os.environ["DYNAMODB_TABLE_NAME"]

    table = boto3.resource("dynamodb").Table(table_name)
    codebuild = boto3.client("codebuild")
    if is_needed_to_delete_codebuild_project(table, repository_name, branch_name):
        logger.debug("Start to delete CodeBuild project")
        delete_codebuild(
            client=codebuild,
            project_name=f"ci-pull-request-{repository_name}-{branch_name_escaped}-id-{pull_request_id}",
        )
    else:
        logger.debug(f"{repository_name} - branch: {branch_name} is in exclusion list")
