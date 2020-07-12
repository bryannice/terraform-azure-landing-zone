terraform {
  backend "${BACKEND_TYPE}" {
    ${SUBSCRIPTION_ID}
    ${TENANT_ID}
    ${CLIENT_ID}
    ${CLIENT_SECRET}
    ${RESOURCE_GROUP_NAME}
    ${STORAGE_ACCOUNT_NAME}
    ${SAS_TOKEN}
    ${ACCESS_KEY}
    ${CONTAINER_NAME}
    ${KEY}
  }
}