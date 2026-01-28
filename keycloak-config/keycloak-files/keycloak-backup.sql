--
-- PostgreSQL database dump
--

\restrict kqpPGPOWgiDizmB4jVZnkVWbGGohgzfwQmiq91x0w1Ybhf9EURhd4gf6JP3VXaU

-- Dumped from database version 15.15
-- Dumped by pg_dump version 15.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_event_entity; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.admin_event_entity (
    id character varying(36) NOT NULL,
    admin_event_time bigint,
    realm_id character varying(255),
    operation_type character varying(255),
    auth_realm_id character varying(255),
    auth_client_id character varying(255),
    auth_user_id character varying(255),
    ip_address character varying(255),
    resource_path character varying(2550),
    representation text,
    error character varying(255),
    resource_type character varying(64),
    details_json text
);


ALTER TABLE public.admin_event_entity OWNER TO keycloak;

--
-- Name: associated_policy; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.associated_policy (
    policy_id character varying(36) NOT NULL,
    associated_policy_id character varying(36) NOT NULL
);


ALTER TABLE public.associated_policy OWNER TO keycloak;

--
-- Name: authentication_execution; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.authentication_execution (
    id character varying(36) NOT NULL,
    alias character varying(255),
    authenticator character varying(36),
    realm_id character varying(36),
    flow_id character varying(36),
    requirement integer,
    priority integer,
    authenticator_flow boolean DEFAULT false NOT NULL,
    auth_flow_id character varying(36),
    auth_config character varying(36)
);


ALTER TABLE public.authentication_execution OWNER TO keycloak;

--
-- Name: authentication_flow; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.authentication_flow (
    id character varying(36) NOT NULL,
    alias character varying(255),
    description character varying(255),
    realm_id character varying(36),
    provider_id character varying(36) DEFAULT 'basic-flow'::character varying NOT NULL,
    top_level boolean DEFAULT false NOT NULL,
    built_in boolean DEFAULT false NOT NULL
);


ALTER TABLE public.authentication_flow OWNER TO keycloak;

--
-- Name: authenticator_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.authenticator_config (
    id character varying(36) NOT NULL,
    alias character varying(255),
    realm_id character varying(36)
);


ALTER TABLE public.authenticator_config OWNER TO keycloak;

--
-- Name: authenticator_config_entry; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.authenticator_config_entry (
    authenticator_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.authenticator_config_entry OWNER TO keycloak;

--
-- Name: broker_link; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.broker_link (
    identity_provider character varying(255) NOT NULL,
    storage_provider_id character varying(255),
    realm_id character varying(36) NOT NULL,
    broker_user_id character varying(255),
    broker_username character varying(255),
    token text,
    user_id character varying(255) NOT NULL
);


ALTER TABLE public.broker_link OWNER TO keycloak;

--
-- Name: client; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client (
    id character varying(36) NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    full_scope_allowed boolean DEFAULT false NOT NULL,
    client_id character varying(255),
    not_before integer,
    public_client boolean DEFAULT false NOT NULL,
    secret character varying(255),
    base_url character varying(255),
    bearer_only boolean DEFAULT false NOT NULL,
    management_url character varying(255),
    surrogate_auth_required boolean DEFAULT false NOT NULL,
    realm_id character varying(36),
    protocol character varying(255),
    node_rereg_timeout integer DEFAULT 0,
    frontchannel_logout boolean DEFAULT false NOT NULL,
    consent_required boolean DEFAULT false NOT NULL,
    name character varying(255),
    service_accounts_enabled boolean DEFAULT false NOT NULL,
    client_authenticator_type character varying(255),
    root_url character varying(255),
    description character varying(255),
    registration_token character varying(255),
    standard_flow_enabled boolean DEFAULT true NOT NULL,
    implicit_flow_enabled boolean DEFAULT false NOT NULL,
    direct_access_grants_enabled boolean DEFAULT false NOT NULL,
    always_display_in_console boolean DEFAULT false NOT NULL
);


ALTER TABLE public.client OWNER TO keycloak;

--
-- Name: client_attributes; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_attributes (
    client_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.client_attributes OWNER TO keycloak;

--
-- Name: client_auth_flow_bindings; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_auth_flow_bindings (
    client_id character varying(36) NOT NULL,
    flow_id character varying(36),
    binding_name character varying(255) NOT NULL
);


ALTER TABLE public.client_auth_flow_bindings OWNER TO keycloak;

--
-- Name: client_initial_access; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_initial_access (
    id character varying(36) NOT NULL,
    realm_id character varying(36) NOT NULL,
    "timestamp" integer,
    expiration integer,
    count integer,
    remaining_count integer
);


ALTER TABLE public.client_initial_access OWNER TO keycloak;

--
-- Name: client_node_registrations; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_node_registrations (
    client_id character varying(36) NOT NULL,
    value integer,
    name character varying(255) NOT NULL
);


ALTER TABLE public.client_node_registrations OWNER TO keycloak;

--
-- Name: client_scope; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_scope (
    id character varying(36) NOT NULL,
    name character varying(255),
    realm_id character varying(36),
    description character varying(255),
    protocol character varying(255)
);


ALTER TABLE public.client_scope OWNER TO keycloak;

--
-- Name: client_scope_attributes; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_scope_attributes (
    scope_id character varying(36) NOT NULL,
    value character varying(2048),
    name character varying(255) NOT NULL
);


ALTER TABLE public.client_scope_attributes OWNER TO keycloak;

--
-- Name: client_scope_client; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_scope_client (
    client_id character varying(255) NOT NULL,
    scope_id character varying(255) NOT NULL,
    default_scope boolean DEFAULT false NOT NULL
);


ALTER TABLE public.client_scope_client OWNER TO keycloak;

--
-- Name: client_scope_role_mapping; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.client_scope_role_mapping (
    scope_id character varying(36) NOT NULL,
    role_id character varying(36) NOT NULL
);


ALTER TABLE public.client_scope_role_mapping OWNER TO keycloak;

--
-- Name: component; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.component (
    id character varying(36) NOT NULL,
    name character varying(255),
    parent_id character varying(36),
    provider_id character varying(36),
    provider_type character varying(255),
    realm_id character varying(36),
    sub_type character varying(255)
);


ALTER TABLE public.component OWNER TO keycloak;

--
-- Name: component_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.component_config (
    id character varying(36) NOT NULL,
    component_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.component_config OWNER TO keycloak;

--
-- Name: composite_role; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.composite_role (
    composite character varying(36) NOT NULL,
    child_role character varying(36) NOT NULL
);


ALTER TABLE public.composite_role OWNER TO keycloak;

--
-- Name: credential; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.credential (
    id character varying(36) NOT NULL,
    salt bytea,
    type character varying(255),
    user_id character varying(36),
    created_date bigint,
    user_label character varying(255),
    secret_data text,
    credential_data text,
    priority integer,
    version integer DEFAULT 0
);


ALTER TABLE public.credential OWNER TO keycloak;

--
-- Name: databasechangelog; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.databasechangelog (
    id character varying(255) NOT NULL,
    author character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    dateexecuted timestamp without time zone NOT NULL,
    orderexecuted integer NOT NULL,
    exectype character varying(10) NOT NULL,
    md5sum character varying(35),
    description character varying(255),
    comments character varying(255),
    tag character varying(255),
    liquibase character varying(20),
    contexts character varying(255),
    labels character varying(255),
    deployment_id character varying(10)
);


ALTER TABLE public.databasechangelog OWNER TO keycloak;

--
-- Name: databasechangeloglock; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.databasechangeloglock (
    id integer NOT NULL,
    locked boolean NOT NULL,
    lockgranted timestamp without time zone,
    lockedby character varying(255)
);


ALTER TABLE public.databasechangeloglock OWNER TO keycloak;

--
-- Name: default_client_scope; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.default_client_scope (
    realm_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL,
    default_scope boolean DEFAULT false NOT NULL
);


ALTER TABLE public.default_client_scope OWNER TO keycloak;

--
-- Name: event_entity; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.event_entity (
    id character varying(36) NOT NULL,
    client_id character varying(255),
    details_json character varying(2550),
    error character varying(255),
    ip_address character varying(255),
    realm_id character varying(255),
    session_id character varying(255),
    event_time bigint,
    type character varying(255),
    user_id character varying(255),
    details_json_long_value text
);


ALTER TABLE public.event_entity OWNER TO keycloak;

--
-- Name: fed_user_attribute; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.fed_user_attribute (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36),
    value character varying(2024),
    long_value_hash bytea,
    long_value_hash_lower_case bytea,
    long_value text
);


ALTER TABLE public.fed_user_attribute OWNER TO keycloak;

--
-- Name: fed_user_consent; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.fed_user_consent (
    id character varying(36) NOT NULL,
    client_id character varying(255),
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36),
    created_date bigint,
    last_updated_date bigint,
    client_storage_provider character varying(36),
    external_client_id character varying(255)
);


ALTER TABLE public.fed_user_consent OWNER TO keycloak;

--
-- Name: fed_user_consent_cl_scope; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.fed_user_consent_cl_scope (
    user_consent_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL
);


ALTER TABLE public.fed_user_consent_cl_scope OWNER TO keycloak;

--
-- Name: fed_user_credential; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.fed_user_credential (
    id character varying(36) NOT NULL,
    salt bytea,
    type character varying(255),
    created_date bigint,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36),
    user_label character varying(255),
    secret_data text,
    credential_data text,
    priority integer
);


ALTER TABLE public.fed_user_credential OWNER TO keycloak;

--
-- Name: fed_user_group_membership; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.fed_user_group_membership (
    group_id character varying(36) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36)
);


ALTER TABLE public.fed_user_group_membership OWNER TO keycloak;

--
-- Name: fed_user_required_action; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.fed_user_required_action (
    required_action character varying(255) DEFAULT ' '::character varying NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36)
);


ALTER TABLE public.fed_user_required_action OWNER TO keycloak;

--
-- Name: fed_user_role_mapping; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.fed_user_role_mapping (
    role_id character varying(36) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36)
);


ALTER TABLE public.fed_user_role_mapping OWNER TO keycloak;

--
-- Name: federated_identity; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.federated_identity (
    identity_provider character varying(255) NOT NULL,
    realm_id character varying(36),
    federated_user_id character varying(255),
    federated_username character varying(255),
    token text,
    user_id character varying(36) NOT NULL
);


ALTER TABLE public.federated_identity OWNER TO keycloak;

--
-- Name: federated_user; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.federated_user (
    id character varying(255) NOT NULL,
    storage_provider_id character varying(255),
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.federated_user OWNER TO keycloak;

--
-- Name: group_attribute; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.group_attribute (
    id character varying(36) DEFAULT 'sybase-needs-something-here'::character varying NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255),
    group_id character varying(36) NOT NULL
);


ALTER TABLE public.group_attribute OWNER TO keycloak;

--
-- Name: group_role_mapping; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.group_role_mapping (
    role_id character varying(36) NOT NULL,
    group_id character varying(36) NOT NULL
);


ALTER TABLE public.group_role_mapping OWNER TO keycloak;

--
-- Name: identity_provider; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.identity_provider (
    internal_id character varying(36) NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    provider_alias character varying(255),
    provider_id character varying(255),
    store_token boolean DEFAULT false NOT NULL,
    authenticate_by_default boolean DEFAULT false NOT NULL,
    realm_id character varying(36),
    add_token_role boolean DEFAULT true NOT NULL,
    trust_email boolean DEFAULT false NOT NULL,
    first_broker_login_flow_id character varying(36),
    post_broker_login_flow_id character varying(36),
    provider_display_name character varying(255),
    link_only boolean DEFAULT false NOT NULL,
    organization_id character varying(255),
    hide_on_login boolean DEFAULT false
);


ALTER TABLE public.identity_provider OWNER TO keycloak;

--
-- Name: identity_provider_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.identity_provider_config (
    identity_provider_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.identity_provider_config OWNER TO keycloak;

--
-- Name: identity_provider_mapper; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.identity_provider_mapper (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    idp_alias character varying(255) NOT NULL,
    idp_mapper_name character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.identity_provider_mapper OWNER TO keycloak;

--
-- Name: idp_mapper_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.idp_mapper_config (
    idp_mapper_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.idp_mapper_config OWNER TO keycloak;

--
-- Name: jgroups_ping; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.jgroups_ping (
    address character varying(200) NOT NULL,
    name character varying(200),
    cluster_name character varying(200) NOT NULL,
    ip character varying(200) NOT NULL,
    coord boolean
);


ALTER TABLE public.jgroups_ping OWNER TO keycloak;

--
-- Name: keycloak_group; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.keycloak_group (
    id character varying(36) NOT NULL,
    name character varying(255),
    parent_group character varying(36) NOT NULL,
    realm_id character varying(36),
    type integer DEFAULT 0 NOT NULL,
    description character varying(255)
);


ALTER TABLE public.keycloak_group OWNER TO keycloak;

--
-- Name: keycloak_role; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.keycloak_role (
    id character varying(36) NOT NULL,
    client_realm_constraint character varying(255),
    client_role boolean DEFAULT false NOT NULL,
    description character varying(255),
    name character varying(255),
    realm_id character varying(255),
    client character varying(36),
    realm character varying(36)
);


ALTER TABLE public.keycloak_role OWNER TO keycloak;

--
-- Name: migration_model; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.migration_model (
    id character varying(36) NOT NULL,
    version character varying(36),
    update_time bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.migration_model OWNER TO keycloak;

--
-- Name: offline_client_session; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.offline_client_session (
    user_session_id character varying(36) NOT NULL,
    client_id character varying(255) NOT NULL,
    offline_flag character varying(4) NOT NULL,
    "timestamp" integer,
    data text,
    client_storage_provider character varying(36) DEFAULT 'local'::character varying NOT NULL,
    external_client_id character varying(255) DEFAULT 'local'::character varying NOT NULL,
    version integer DEFAULT 0
);


ALTER TABLE public.offline_client_session OWNER TO keycloak;

--
-- Name: offline_user_session; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.offline_user_session (
    user_session_id character varying(36) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    created_on integer NOT NULL,
    offline_flag character varying(4) NOT NULL,
    data text,
    last_session_refresh integer DEFAULT 0 NOT NULL,
    broker_session_id character varying(1024),
    version integer DEFAULT 0
);


ALTER TABLE public.offline_user_session OWNER TO keycloak;

--
-- Name: org; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.org (
    id character varying(255) NOT NULL,
    enabled boolean NOT NULL,
    realm_id character varying(255) NOT NULL,
    group_id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(4000),
    alias character varying(255) NOT NULL,
    redirect_url character varying(2048)
);


ALTER TABLE public.org OWNER TO keycloak;

--
-- Name: org_domain; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.org_domain (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    verified boolean NOT NULL,
    org_id character varying(255) NOT NULL
);


ALTER TABLE public.org_domain OWNER TO keycloak;

--
-- Name: policy_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.policy_config (
    policy_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.policy_config OWNER TO keycloak;

--
-- Name: protocol_mapper; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.protocol_mapper (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    protocol character varying(255) NOT NULL,
    protocol_mapper_name character varying(255) NOT NULL,
    client_id character varying(36),
    client_scope_id character varying(36)
);


ALTER TABLE public.protocol_mapper OWNER TO keycloak;

--
-- Name: protocol_mapper_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.protocol_mapper_config (
    protocol_mapper_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.protocol_mapper_config OWNER TO keycloak;

--
-- Name: realm; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm (
    id character varying(36) NOT NULL,
    access_code_lifespan integer,
    user_action_lifespan integer,
    access_token_lifespan integer,
    account_theme character varying(255),
    admin_theme character varying(255),
    email_theme character varying(255),
    enabled boolean DEFAULT false NOT NULL,
    events_enabled boolean DEFAULT false NOT NULL,
    events_expiration bigint,
    login_theme character varying(255),
    name character varying(255),
    not_before integer,
    password_policy character varying(2550),
    registration_allowed boolean DEFAULT false NOT NULL,
    remember_me boolean DEFAULT false NOT NULL,
    reset_password_allowed boolean DEFAULT false NOT NULL,
    social boolean DEFAULT false NOT NULL,
    ssl_required character varying(255),
    sso_idle_timeout integer,
    sso_max_lifespan integer,
    update_profile_on_soc_login boolean DEFAULT false NOT NULL,
    verify_email boolean DEFAULT false NOT NULL,
    master_admin_client character varying(36),
    login_lifespan integer,
    internationalization_enabled boolean DEFAULT false NOT NULL,
    default_locale character varying(255),
    reg_email_as_username boolean DEFAULT false NOT NULL,
    admin_events_enabled boolean DEFAULT false NOT NULL,
    admin_events_details_enabled boolean DEFAULT false NOT NULL,
    edit_username_allowed boolean DEFAULT false NOT NULL,
    otp_policy_counter integer DEFAULT 0,
    otp_policy_window integer DEFAULT 1,
    otp_policy_period integer DEFAULT 30,
    otp_policy_digits integer DEFAULT 6,
    otp_policy_alg character varying(36) DEFAULT 'HmacSHA1'::character varying,
    otp_policy_type character varying(36) DEFAULT 'totp'::character varying,
    browser_flow character varying(36),
    registration_flow character varying(36),
    direct_grant_flow character varying(36),
    reset_credentials_flow character varying(36),
    client_auth_flow character varying(36),
    offline_session_idle_timeout integer DEFAULT 0,
    revoke_refresh_token boolean DEFAULT false NOT NULL,
    access_token_life_implicit integer DEFAULT 0,
    login_with_email_allowed boolean DEFAULT true NOT NULL,
    duplicate_emails_allowed boolean DEFAULT false NOT NULL,
    docker_auth_flow character varying(36),
    refresh_token_max_reuse integer DEFAULT 0,
    allow_user_managed_access boolean DEFAULT false NOT NULL,
    sso_max_lifespan_remember_me integer DEFAULT 0 NOT NULL,
    sso_idle_timeout_remember_me integer DEFAULT 0 NOT NULL,
    default_role character varying(255)
);


ALTER TABLE public.realm OWNER TO keycloak;

--
-- Name: realm_attribute; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_attribute (
    name character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    value text
);


ALTER TABLE public.realm_attribute OWNER TO keycloak;

--
-- Name: realm_default_groups; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_default_groups (
    realm_id character varying(36) NOT NULL,
    group_id character varying(36) NOT NULL
);


ALTER TABLE public.realm_default_groups OWNER TO keycloak;

--
-- Name: realm_enabled_event_types; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_enabled_event_types (
    realm_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.realm_enabled_event_types OWNER TO keycloak;

--
-- Name: realm_events_listeners; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_events_listeners (
    realm_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.realm_events_listeners OWNER TO keycloak;

--
-- Name: realm_localizations; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_localizations (
    realm_id character varying(255) NOT NULL,
    locale character varying(255) NOT NULL,
    texts text NOT NULL
);


ALTER TABLE public.realm_localizations OWNER TO keycloak;

--
-- Name: realm_required_credential; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_required_credential (
    type character varying(255) NOT NULL,
    form_label character varying(255),
    input boolean DEFAULT false NOT NULL,
    secret boolean DEFAULT false NOT NULL,
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.realm_required_credential OWNER TO keycloak;

--
-- Name: realm_smtp_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_smtp_config (
    realm_id character varying(36) NOT NULL,
    value character varying(255),
    name character varying(255) NOT NULL
);


ALTER TABLE public.realm_smtp_config OWNER TO keycloak;

--
-- Name: realm_supported_locales; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.realm_supported_locales (
    realm_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.realm_supported_locales OWNER TO keycloak;

--
-- Name: redirect_uris; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.redirect_uris (
    client_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.redirect_uris OWNER TO keycloak;

--
-- Name: required_action_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.required_action_config (
    required_action_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.required_action_config OWNER TO keycloak;

--
-- Name: required_action_provider; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.required_action_provider (
    id character varying(36) NOT NULL,
    alias character varying(255),
    name character varying(255),
    realm_id character varying(36),
    enabled boolean DEFAULT false NOT NULL,
    default_action boolean DEFAULT false NOT NULL,
    provider_id character varying(255),
    priority integer
);


ALTER TABLE public.required_action_provider OWNER TO keycloak;

--
-- Name: resource_attribute; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_attribute (
    id character varying(36) DEFAULT 'sybase-needs-something-here'::character varying NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255),
    resource_id character varying(36) NOT NULL
);


ALTER TABLE public.resource_attribute OWNER TO keycloak;

--
-- Name: resource_policy; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_policy (
    resource_id character varying(36) NOT NULL,
    policy_id character varying(36) NOT NULL
);


ALTER TABLE public.resource_policy OWNER TO keycloak;

--
-- Name: resource_scope; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_scope (
    resource_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL
);


ALTER TABLE public.resource_scope OWNER TO keycloak;

--
-- Name: resource_server; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_server (
    id character varying(36) NOT NULL,
    allow_rs_remote_mgmt boolean DEFAULT false NOT NULL,
    policy_enforce_mode smallint NOT NULL,
    decision_strategy smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.resource_server OWNER TO keycloak;

--
-- Name: resource_server_perm_ticket; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_server_perm_ticket (
    id character varying(36) NOT NULL,
    owner character varying(255) NOT NULL,
    requester character varying(255) NOT NULL,
    created_timestamp bigint NOT NULL,
    granted_timestamp bigint,
    resource_id character varying(36) NOT NULL,
    scope_id character varying(36),
    resource_server_id character varying(36) NOT NULL,
    policy_id character varying(36)
);


ALTER TABLE public.resource_server_perm_ticket OWNER TO keycloak;

--
-- Name: resource_server_policy; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_server_policy (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    type character varying(255) NOT NULL,
    decision_strategy smallint,
    logic smallint,
    resource_server_id character varying(36) NOT NULL,
    owner character varying(255)
);


ALTER TABLE public.resource_server_policy OWNER TO keycloak;

--
-- Name: resource_server_resource; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_server_resource (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255),
    icon_uri character varying(255),
    owner character varying(255) NOT NULL,
    resource_server_id character varying(36) NOT NULL,
    owner_managed_access boolean DEFAULT false NOT NULL,
    display_name character varying(255)
);


ALTER TABLE public.resource_server_resource OWNER TO keycloak;

--
-- Name: resource_server_scope; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_server_scope (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    icon_uri character varying(255),
    resource_server_id character varying(36) NOT NULL,
    display_name character varying(255)
);


ALTER TABLE public.resource_server_scope OWNER TO keycloak;

--
-- Name: resource_uris; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.resource_uris (
    resource_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.resource_uris OWNER TO keycloak;

--
-- Name: revoked_token; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.revoked_token (
    id character varying(255) NOT NULL,
    expire bigint NOT NULL
);


ALTER TABLE public.revoked_token OWNER TO keycloak;

--
-- Name: role_attribute; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.role_attribute (
    id character varying(36) NOT NULL,
    role_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255)
);


ALTER TABLE public.role_attribute OWNER TO keycloak;

--
-- Name: scope_mapping; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.scope_mapping (
    client_id character varying(36) NOT NULL,
    role_id character varying(36) NOT NULL
);


ALTER TABLE public.scope_mapping OWNER TO keycloak;

--
-- Name: scope_policy; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.scope_policy (
    scope_id character varying(36) NOT NULL,
    policy_id character varying(36) NOT NULL
);


ALTER TABLE public.scope_policy OWNER TO keycloak;

--
-- Name: server_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.server_config (
    server_config_key character varying(255) NOT NULL,
    value text NOT NULL,
    version integer DEFAULT 0
);


ALTER TABLE public.server_config OWNER TO keycloak;

--
-- Name: user_attribute; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_attribute (
    name character varying(255) NOT NULL,
    value character varying(255),
    user_id character varying(36) NOT NULL,
    id character varying(36) DEFAULT 'sybase-needs-something-here'::character varying NOT NULL,
    long_value_hash bytea,
    long_value_hash_lower_case bytea,
    long_value text
);


ALTER TABLE public.user_attribute OWNER TO keycloak;

--
-- Name: user_consent; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_consent (
    id character varying(36) NOT NULL,
    client_id character varying(255),
    user_id character varying(36) NOT NULL,
    created_date bigint,
    last_updated_date bigint,
    client_storage_provider character varying(36),
    external_client_id character varying(255)
);


ALTER TABLE public.user_consent OWNER TO keycloak;

--
-- Name: user_consent_client_scope; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_consent_client_scope (
    user_consent_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL
);


ALTER TABLE public.user_consent_client_scope OWNER TO keycloak;

--
-- Name: user_entity; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_entity (
    id character varying(36) NOT NULL,
    email character varying(255),
    email_constraint character varying(255),
    email_verified boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    federation_link character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    realm_id character varying(255),
    username character varying(255),
    created_timestamp bigint,
    service_account_client_link character varying(255),
    not_before integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.user_entity OWNER TO keycloak;

--
-- Name: user_federation_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_federation_config (
    user_federation_provider_id character varying(36) NOT NULL,
    value character varying(255),
    name character varying(255) NOT NULL
);


ALTER TABLE public.user_federation_config OWNER TO keycloak;

--
-- Name: user_federation_mapper; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_federation_mapper (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    federation_provider_id character varying(36) NOT NULL,
    federation_mapper_type character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.user_federation_mapper OWNER TO keycloak;

--
-- Name: user_federation_mapper_config; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_federation_mapper_config (
    user_federation_mapper_id character varying(36) NOT NULL,
    value character varying(255),
    name character varying(255) NOT NULL
);


ALTER TABLE public.user_federation_mapper_config OWNER TO keycloak;

--
-- Name: user_federation_provider; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_federation_provider (
    id character varying(36) NOT NULL,
    changed_sync_period integer,
    display_name character varying(255),
    full_sync_period integer,
    last_sync integer,
    priority integer,
    provider_name character varying(255),
    realm_id character varying(36)
);


ALTER TABLE public.user_federation_provider OWNER TO keycloak;

--
-- Name: user_group_membership; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_group_membership (
    group_id character varying(36) NOT NULL,
    user_id character varying(36) NOT NULL,
    membership_type character varying(255) NOT NULL
);


ALTER TABLE public.user_group_membership OWNER TO keycloak;

--
-- Name: user_required_action; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_required_action (
    user_id character varying(36) NOT NULL,
    required_action character varying(255) DEFAULT ' '::character varying NOT NULL
);


ALTER TABLE public.user_required_action OWNER TO keycloak;

--
-- Name: user_role_mapping; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.user_role_mapping (
    role_id character varying(255) NOT NULL,
    user_id character varying(36) NOT NULL
);


ALTER TABLE public.user_role_mapping OWNER TO keycloak;

--
-- Name: web_origins; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.web_origins (
    client_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.web_origins OWNER TO keycloak;

--
-- Name: workflow_state; Type: TABLE; Schema: public; Owner: keycloak
--

CREATE TABLE public.workflow_state (
    execution_id character varying(255) NOT NULL,
    resource_id character varying(255) NOT NULL,
    workflow_id character varying(255) NOT NULL,
    workflow_provider_id character varying(255),
    resource_type character varying(255),
    scheduled_step_id character varying(255),
    scheduled_step_timestamp bigint
);


ALTER TABLE public.workflow_state OWNER TO keycloak;

--
-- Data for Name: admin_event_entity; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.admin_event_entity (id, admin_event_time, realm_id, operation_type, auth_realm_id, auth_client_id, auth_user_id, ip_address, resource_path, representation, error, resource_type, details_json) FROM stdin;
\.


--
-- Data for Name: associated_policy; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.associated_policy (policy_id, associated_policy_id) FROM stdin;
5c503412-0dea-4d9d-9fd0-d9cf36f4628e	cf031263-2240-4e3a-aa66-435d8be13bda
5c503412-0dea-4d9d-9fd0-d9cf36f4628e	0b3e0ae3-9d52-4e27-9cce-4df78f6f1b13
2a86201c-56b1-4f98-b727-16b8f55988ff	f0097b3d-896d-4bca-a1a6-2f23f67c4179
2a86201c-56b1-4f98-b727-16b8f55988ff	cf031263-2240-4e3a-aa66-435d8be13bda
efd93021-7e76-4202-ba03-d89330a48f66	5c503412-0dea-4d9d-9fd0-d9cf36f4628e
9661b3f8-a5f8-4e30-ac49-af00b078e62f	5c503412-0dea-4d9d-9fd0-d9cf36f4628e
18e46344-009c-4b0e-a943-c58960ee9871	2a86201c-56b1-4f98-b727-16b8f55988ff
b9870a4c-1b3e-48d8-b633-b6d89910f1be	cf031263-2240-4e3a-aa66-435d8be13bda
5475198b-e4a2-40bc-8fa5-a9c9a87596f2	5c503412-0dea-4d9d-9fd0-d9cf36f4628e
21b596be-00a8-4d19-9456-f2cb1b6e5242	2a86201c-56b1-4f98-b727-16b8f55988ff
6a039833-ded3-4195-9f18-e9fc6f9e31b2	cf031263-2240-4e3a-aa66-435d8be13bda
adb786c1-c6c1-4db1-b4b1-607cab3085c7	5c503412-0dea-4d9d-9fd0-d9cf36f4628e
fed1f1bf-3054-4aa9-985d-17487fb0e263	2a86201c-56b1-4f98-b727-16b8f55988ff
85594e45-be39-41e2-818a-75113a4d07b4	cf031263-2240-4e3a-aa66-435d8be13bda
494d18f3-70fa-49b5-8e0f-b40f3c5cd258	5c503412-0dea-4d9d-9fd0-d9cf36f4628e
35245166-481f-4bb9-9e7c-b31907128b21	2a86201c-56b1-4f98-b727-16b8f55988ff
07d1240c-0b98-4b82-90fa-7ceb09fbd5da	cf031263-2240-4e3a-aa66-435d8be13bda
647de62c-fbb7-4310-a5b6-3e4fc20d1c7d	1ef90841-93bb-443c-a405-2fb028e4c2cb
b3394fda-9dda-4f92-b07c-e2cbe35c2ec8	1ef90841-93bb-443c-a405-2fb028e4c2cb
feb85689-e557-409d-a01a-dd606952baf3	1ef90841-93bb-443c-a405-2fb028e4c2cb
d7af2a0a-2273-4768-b0c2-d85d8aca3011	b142bc58-efb0-448d-9203-66894c6aac16
31044763-9265-48d2-a508-be0cd5430292	76050c35-6e2e-4ef8-8769-b4c6354116dc
9a313617-6544-449e-a2aa-abb3eb9eb589	b142bc58-efb0-448d-9203-66894c6aac16
\.


--
-- Data for Name: authentication_execution; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.authentication_execution (id, alias, authenticator, realm_id, flow_id, requirement, priority, authenticator_flow, auth_flow_id, auth_config) FROM stdin;
62ab9a03-fc6c-444a-ac3b-c1e849b04b61	\N	auth-cookie	955a00d0-1411-4e86-8ef2-bdedffd7a66f	88720b08-0957-4146-9ac9-60ffcb0cf8c0	2	10	f	\N	\N
c4021181-e92e-46a0-bfd0-d9509641c39a	\N	auth-spnego	955a00d0-1411-4e86-8ef2-bdedffd7a66f	88720b08-0957-4146-9ac9-60ffcb0cf8c0	3	20	f	\N	\N
315c84e4-d7a3-46cb-a097-d7be33a80a06	\N	identity-provider-redirector	955a00d0-1411-4e86-8ef2-bdedffd7a66f	88720b08-0957-4146-9ac9-60ffcb0cf8c0	2	25	f	\N	\N
05cc4d8b-ea23-45c3-9068-1721e460268d	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	88720b08-0957-4146-9ac9-60ffcb0cf8c0	2	30	t	39a77907-ba51-43af-a6c2-74e0ba82da0e	\N
d757214b-c9c4-4bf5-9430-07b03e690bbc	\N	auth-username-password-form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	39a77907-ba51-43af-a6c2-74e0ba82da0e	0	10	f	\N	\N
8ec86d0f-2d73-43e8-bca4-3c5026d4cea8	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	39a77907-ba51-43af-a6c2-74e0ba82da0e	1	20	t	c2a9714b-58b4-47fe-b507-1194ab67b237	\N
1c2db64e-c178-4e41-9198-fed4c444b0e4	\N	conditional-user-configured	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c2a9714b-58b4-47fe-b507-1194ab67b237	0	10	f	\N	\N
4e0f4c6f-f5a8-4ddc-9b97-90ba7b606041	\N	conditional-credential	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c2a9714b-58b4-47fe-b507-1194ab67b237	0	20	f	\N	2cd6a5ea-63e8-4529-98fe-da89813e6372
a45efbd7-1dab-420e-a4ac-b7c5e583c16d	\N	auth-otp-form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c2a9714b-58b4-47fe-b507-1194ab67b237	2	30	f	\N	\N
5e3dd711-23e1-43d2-a121-6ca0af63b749	\N	webauthn-authenticator	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c2a9714b-58b4-47fe-b507-1194ab67b237	3	40	f	\N	\N
adad0576-573e-4f1f-bbec-ff43d4a68a94	\N	auth-recovery-authn-code-form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c2a9714b-58b4-47fe-b507-1194ab67b237	3	50	f	\N	\N
4530ef67-9a18-443e-8bb9-04a0dda1adea	\N	direct-grant-validate-username	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c142818d-e1c3-4984-bcd6-668e0e7b5c9a	0	10	f	\N	\N
1847b9dc-fd7d-4576-a4c5-ef6f7f3ef8ea	\N	direct-grant-validate-password	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c142818d-e1c3-4984-bcd6-668e0e7b5c9a	0	20	f	\N	\N
a53c1d44-d381-4ce4-b3cd-87954eae9486	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c142818d-e1c3-4984-bcd6-668e0e7b5c9a	1	30	t	ddefde89-5a92-4028-a559-1df859bc2595	\N
a26e67e7-7b8c-423f-8074-ff7ec0e8d5a2	\N	conditional-user-configured	955a00d0-1411-4e86-8ef2-bdedffd7a66f	ddefde89-5a92-4028-a559-1df859bc2595	0	10	f	\N	\N
dda88527-305f-40d2-8ee0-b6ee8b3995af	\N	direct-grant-validate-otp	955a00d0-1411-4e86-8ef2-bdedffd7a66f	ddefde89-5a92-4028-a559-1df859bc2595	0	20	f	\N	\N
28729800-fe1c-4695-9429-b4b6bfec788b	\N	registration-page-form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	20508aef-657a-438f-8d43-7246a41916bc	0	10	t	8c62e418-6a46-4341-a670-154739492ed9	\N
f905f53f-528f-4f2d-a40f-0099e430261d	\N	registration-user-creation	955a00d0-1411-4e86-8ef2-bdedffd7a66f	8c62e418-6a46-4341-a670-154739492ed9	0	20	f	\N	\N
5b86eeb7-6504-4f13-adb0-1c73d888ae1e	\N	registration-password-action	955a00d0-1411-4e86-8ef2-bdedffd7a66f	8c62e418-6a46-4341-a670-154739492ed9	0	50	f	\N	\N
95403282-c94b-4d62-b8f7-e3824ac17fe3	\N	registration-recaptcha-action	955a00d0-1411-4e86-8ef2-bdedffd7a66f	8c62e418-6a46-4341-a670-154739492ed9	3	60	f	\N	\N
80f7477f-c646-4351-a1ec-72942fb8c24b	\N	registration-terms-and-conditions	955a00d0-1411-4e86-8ef2-bdedffd7a66f	8c62e418-6a46-4341-a670-154739492ed9	3	70	f	\N	\N
c06f7981-8968-4f48-ae3e-d98d11d59dba	\N	reset-credentials-choose-user	955a00d0-1411-4e86-8ef2-bdedffd7a66f	52ecf8dd-e190-4618-b195-ad7ef4bac05e	0	10	f	\N	\N
65bd4cab-9f91-490c-8124-cda92d043925	\N	reset-credential-email	955a00d0-1411-4e86-8ef2-bdedffd7a66f	52ecf8dd-e190-4618-b195-ad7ef4bac05e	0	20	f	\N	\N
b3c3a43d-dda0-4512-9188-6fcab536a973	\N	reset-password	955a00d0-1411-4e86-8ef2-bdedffd7a66f	52ecf8dd-e190-4618-b195-ad7ef4bac05e	0	30	f	\N	\N
26025e78-bf5f-4fc7-8a13-18b0beceb998	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	52ecf8dd-e190-4618-b195-ad7ef4bac05e	1	40	t	0dd7935e-3ba1-4bf5-95df-c5e0c5db5b6d	\N
b680fc70-91c3-4cf0-afd0-0e8903fe2124	\N	conditional-user-configured	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0dd7935e-3ba1-4bf5-95df-c5e0c5db5b6d	0	10	f	\N	\N
8a498bf1-9fa8-41c9-8fac-021176c76e52	\N	reset-otp	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0dd7935e-3ba1-4bf5-95df-c5e0c5db5b6d	0	20	f	\N	\N
981c7076-570c-4410-ae8d-f1014b83b86e	\N	client-secret	955a00d0-1411-4e86-8ef2-bdedffd7a66f	a4982cc5-a485-4514-b1b9-cde6b785f8e3	2	10	f	\N	\N
dfd30c3b-9ce1-4be9-a76d-fbb4301e7931	\N	client-jwt	955a00d0-1411-4e86-8ef2-bdedffd7a66f	a4982cc5-a485-4514-b1b9-cde6b785f8e3	2	20	f	\N	\N
df2d449e-5dcf-4f9a-93cd-4b8e20a3dc08	\N	client-secret-jwt	955a00d0-1411-4e86-8ef2-bdedffd7a66f	a4982cc5-a485-4514-b1b9-cde6b785f8e3	2	30	f	\N	\N
641e22f3-f59f-44d7-9f22-c25989b271a8	\N	client-x509	955a00d0-1411-4e86-8ef2-bdedffd7a66f	a4982cc5-a485-4514-b1b9-cde6b785f8e3	2	40	f	\N	\N
30d01a90-5b65-4985-859f-852171cfaee1	\N	idp-review-profile	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c77a8f72-35a6-4abe-b855-546a1c7ec8f6	0	10	f	\N	e5668454-2827-4f0c-960f-7ea567dc9e35
cdebbeb1-08be-4f16-8ef6-ed114791b87a	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c77a8f72-35a6-4abe-b855-546a1c7ec8f6	0	20	t	92968cf4-9f76-4561-992f-53c5cf405c69	\N
a032ccf3-e09d-4d85-b27a-8aa1a101f9ca	\N	idp-create-user-if-unique	955a00d0-1411-4e86-8ef2-bdedffd7a66f	92968cf4-9f76-4561-992f-53c5cf405c69	2	10	f	\N	848e350e-7a9d-4301-9d03-a82acbd9ca23
66e41d39-38f4-451e-8d12-7ff7bc870b45	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	92968cf4-9f76-4561-992f-53c5cf405c69	2	20	t	74700261-852e-4c32-827d-7365d40dd33d	\N
6ba0d888-8e35-4719-9399-95d5b85979d7	\N	idp-confirm-link	955a00d0-1411-4e86-8ef2-bdedffd7a66f	74700261-852e-4c32-827d-7365d40dd33d	0	10	f	\N	\N
b362dd4d-67e0-40e2-aff6-ba3cd3ccefc2	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	74700261-852e-4c32-827d-7365d40dd33d	0	20	t	2b7cb72d-9935-48d0-97ce-8ec91a80ae94	\N
038416a9-4fe0-4451-beeb-5e569768b5f0	\N	idp-email-verification	955a00d0-1411-4e86-8ef2-bdedffd7a66f	2b7cb72d-9935-48d0-97ce-8ec91a80ae94	2	10	f	\N	\N
32bd09fc-1647-4d02-8412-b440cf4ef73b	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	2b7cb72d-9935-48d0-97ce-8ec91a80ae94	2	20	t	143d1334-40f2-454f-a53f-b49426e700bc	\N
bd189712-1949-4b38-9a94-6faf3db8692d	\N	idp-username-password-form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	143d1334-40f2-454f-a53f-b49426e700bc	0	10	f	\N	\N
f033a220-c252-47db-aeeb-fdb8008d8ca0	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	143d1334-40f2-454f-a53f-b49426e700bc	1	20	t	03be9617-a7ff-40aa-a845-41011b6fcf44	\N
52edd28f-fe8f-4cf0-9b0b-deab9d042dee	\N	conditional-user-configured	955a00d0-1411-4e86-8ef2-bdedffd7a66f	03be9617-a7ff-40aa-a845-41011b6fcf44	0	10	f	\N	\N
c482fca3-9a72-4e83-9f8c-88acfccde21c	\N	conditional-credential	955a00d0-1411-4e86-8ef2-bdedffd7a66f	03be9617-a7ff-40aa-a845-41011b6fcf44	0	20	f	\N	94b653df-682f-41d7-b2b0-fdb9186fd568
00e0287f-13a4-4e3e-ba13-743fb9a7fc42	\N	auth-otp-form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	03be9617-a7ff-40aa-a845-41011b6fcf44	2	30	f	\N	\N
d53c96e1-29c6-473d-9521-67b7f8d5122d	\N	webauthn-authenticator	955a00d0-1411-4e86-8ef2-bdedffd7a66f	03be9617-a7ff-40aa-a845-41011b6fcf44	3	40	f	\N	\N
90c4ecab-0892-4cd4-8dbc-02bcaf9807a4	\N	auth-recovery-authn-code-form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	03be9617-a7ff-40aa-a845-41011b6fcf44	3	50	f	\N	\N
cdd43b80-ec1e-4c9d-b682-9d10aca6f011	\N	http-basic-authenticator	955a00d0-1411-4e86-8ef2-bdedffd7a66f	26460c35-458c-49b7-9f44-638c28923896	0	10	f	\N	\N
528b1f36-b873-4890-a8be-0eef7542840f	\N	docker-http-basic-authenticator	955a00d0-1411-4e86-8ef2-bdedffd7a66f	bc147e2e-9c46-4f64-938c-5b0c54b8e2d2	0	10	f	\N	\N
dffd5ac0-a7f7-4b72-9a63-fdcc9b0acfd1	\N	idp-email-verification	27d57df0-0794-4e96-92ac-85b802200864	0662e4c9-15cc-4b92-88d5-a4d544134f4a	2	10	f	\N	\N
a86dc1e2-fff2-41e6-b8d4-d5791d774256	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	0662e4c9-15cc-4b92-88d5-a4d544134f4a	2	20	t	b581c880-e14c-43b8-aa4b-d535a4158307	\N
f31e1f29-75cf-4dc6-b2de-c6159e3e3ada	\N	conditional-user-configured	27d57df0-0794-4e96-92ac-85b802200864	db9fb3da-7bc6-4991-9d6b-ccd4ed1dea2c	0	10	f	\N	\N
00165598-321a-44a0-9618-dfae7500b28d	\N	auth-otp-form	27d57df0-0794-4e96-92ac-85b802200864	db9fb3da-7bc6-4991-9d6b-ccd4ed1dea2c	0	20	f	\N	\N
050ec7d8-97ec-4c98-910e-14b48e3233fb	\N	conditional-user-configured	27d57df0-0794-4e96-92ac-85b802200864	87ae6868-baec-4183-9138-7b960892e64d	0	10	f	\N	\N
56bee218-9ec0-430f-b00a-d8a50a3e1d55	\N	organization	27d57df0-0794-4e96-92ac-85b802200864	87ae6868-baec-4183-9138-7b960892e64d	2	20	f	\N	\N
eb940a00-f7b6-4459-95c8-54e80accee18	\N	conditional-user-configured	27d57df0-0794-4e96-92ac-85b802200864	87cc3ca5-16a1-4fe8-9593-9fa0ae5023d6	0	10	f	\N	\N
9967a002-5a40-45ad-9406-b712ca0ee17a	\N	direct-grant-validate-otp	27d57df0-0794-4e96-92ac-85b802200864	87cc3ca5-16a1-4fe8-9593-9fa0ae5023d6	0	20	f	\N	\N
06e4a2ea-8e8b-424a-8686-72dc65a3ce65	\N	conditional-user-configured	27d57df0-0794-4e96-92ac-85b802200864	6cf3eca2-86b4-4ef8-b99d-2fbc5e7032e9	0	10	f	\N	\N
98fc1a35-23c4-4871-8232-387be8194089	\N	idp-add-organization-member	27d57df0-0794-4e96-92ac-85b802200864	6cf3eca2-86b4-4ef8-b99d-2fbc5e7032e9	0	20	f	\N	\N
80d7cb56-1e2f-4736-99ae-8f863a7936b8	\N	conditional-user-configured	27d57df0-0794-4e96-92ac-85b802200864	317b2bbe-bb7b-4b21-b1d1-c8b64af88058	0	10	f	\N	\N
21c6f0e6-32a2-4840-898b-d9b8e1f7c0a4	\N	auth-otp-form	27d57df0-0794-4e96-92ac-85b802200864	317b2bbe-bb7b-4b21-b1d1-c8b64af88058	0	20	f	\N	\N
61010705-c406-48be-ab6e-757d46e5cf55	\N	idp-confirm-link	27d57df0-0794-4e96-92ac-85b802200864	f81eb67b-c68d-4e7d-b569-64e525d013f3	0	10	f	\N	\N
6da0777b-e15c-4c02-be31-45d090fafc3d	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	f81eb67b-c68d-4e7d-b569-64e525d013f3	0	20	t	0662e4c9-15cc-4b92-88d5-a4d544134f4a	\N
3d74beb4-67c0-4ba2-a2ef-d0faea503835	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	f6a078df-b8d0-46fd-bdeb-016bf0f39098	1	10	t	87ae6868-baec-4183-9138-7b960892e64d	\N
75deb555-f2dc-4e3f-a1ec-ea779e1605f3	\N	conditional-user-configured	27d57df0-0794-4e96-92ac-85b802200864	66027234-9ca9-4325-b797-16ae7ce65bb1	0	10	f	\N	\N
d867cd1a-e618-4c83-92e3-2df9a21a29e5	\N	reset-otp	27d57df0-0794-4e96-92ac-85b802200864	66027234-9ca9-4325-b797-16ae7ce65bb1	0	20	f	\N	\N
f3bd71ad-3251-4170-9254-44fe25b13298	\N	idp-create-user-if-unique	27d57df0-0794-4e96-92ac-85b802200864	a02ab114-ddc5-42cf-8c0f-0836ec2081f8	2	10	f	\N	f34eb683-7dca-4a52-9ec2-077f35f3a8ce
2086faaa-6eb8-4237-a8be-a1d6ba779f15	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	a02ab114-ddc5-42cf-8c0f-0836ec2081f8	2	20	t	f81eb67b-c68d-4e7d-b569-64e525d013f3	\N
d7da26b5-728d-46a0-a341-ae668397d084	\N	idp-username-password-form	27d57df0-0794-4e96-92ac-85b802200864	b581c880-e14c-43b8-aa4b-d535a4158307	0	10	f	\N	\N
99bb01e4-ba74-4882-9025-48a710d0056f	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	b581c880-e14c-43b8-aa4b-d535a4158307	1	20	t	317b2bbe-bb7b-4b21-b1d1-c8b64af88058	\N
1e0e6208-dd7e-404c-9b12-89d2ebcae937	\N	auth-cookie	27d57df0-0794-4e96-92ac-85b802200864	11c1887b-aef0-4eb9-a262-e1222b430dcf	2	10	f	\N	\N
b93ffd97-8716-4455-9318-9fded7113b13	\N	auth-spnego	27d57df0-0794-4e96-92ac-85b802200864	11c1887b-aef0-4eb9-a262-e1222b430dcf	3	20	f	\N	\N
19720b5c-a999-4990-a850-dc6656659219	\N	identity-provider-redirector	27d57df0-0794-4e96-92ac-85b802200864	11c1887b-aef0-4eb9-a262-e1222b430dcf	2	25	f	\N	\N
b1d7c101-daf1-425b-85db-eb90dd37c347	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	11c1887b-aef0-4eb9-a262-e1222b430dcf	2	26	t	f6a078df-b8d0-46fd-bdeb-016bf0f39098	\N
0bcb22ed-deee-4480-8fad-d078435998b8	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	11c1887b-aef0-4eb9-a262-e1222b430dcf	2	30	t	96b17d9f-be1f-482f-bd8c-2766c182a4a5	\N
ba5f67da-0c5a-4f21-af2e-759815ebd956	\N	client-secret	27d57df0-0794-4e96-92ac-85b802200864	08839456-c079-4f3d-8dd9-64e924cd83cd	2	10	f	\N	\N
0e9d078b-873a-4d53-98a0-64cd9e091822	\N	client-jwt	27d57df0-0794-4e96-92ac-85b802200864	08839456-c079-4f3d-8dd9-64e924cd83cd	2	20	f	\N	\N
30a7f266-14ab-4996-a865-6468361c7641	\N	client-secret-jwt	27d57df0-0794-4e96-92ac-85b802200864	08839456-c079-4f3d-8dd9-64e924cd83cd	2	30	f	\N	\N
f1ec0718-167e-4dcd-aad6-0e9be5f5753c	\N	client-x509	27d57df0-0794-4e96-92ac-85b802200864	08839456-c079-4f3d-8dd9-64e924cd83cd	2	40	f	\N	\N
4303f958-01e8-4118-930d-331de23709d2	\N	direct-grant-validate-username	27d57df0-0794-4e96-92ac-85b802200864	e282ad24-f7b9-4537-a897-55ffae46f8a8	0	10	f	\N	\N
11bcea87-de73-43ca-a9c9-4bba598daaed	\N	direct-grant-validate-password	27d57df0-0794-4e96-92ac-85b802200864	e282ad24-f7b9-4537-a897-55ffae46f8a8	0	20	f	\N	\N
7db8ba9d-8e9f-4d88-abe8-1f41107adc41	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	e282ad24-f7b9-4537-a897-55ffae46f8a8	1	30	t	87cc3ca5-16a1-4fe8-9593-9fa0ae5023d6	\N
733b7ca1-e2f6-4061-9a84-b3e51e2f0597	\N	docker-http-basic-authenticator	27d57df0-0794-4e96-92ac-85b802200864	10c92f67-3d8c-49c3-8f88-acebd3ca9d0c	0	10	f	\N	\N
5407e253-dc4e-40df-b24f-f457e624f941	\N	idp-review-profile	27d57df0-0794-4e96-92ac-85b802200864	b90b5d9b-cbdc-4b9f-b90d-881cf34c943d	0	10	f	\N	15d09fdd-c8c7-4ce2-8a6c-242e74d97618
bc006e99-dfdf-47cd-8e77-535147377f80	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	b90b5d9b-cbdc-4b9f-b90d-881cf34c943d	0	20	t	a02ab114-ddc5-42cf-8c0f-0836ec2081f8	\N
9a67ad19-0bda-489b-a6ff-2a4d778c9858	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	b90b5d9b-cbdc-4b9f-b90d-881cf34c943d	1	50	t	6cf3eca2-86b4-4ef8-b99d-2fbc5e7032e9	\N
a5246ac8-e3f9-493b-a5ba-b7a203137f6e	\N	auth-username-password-form	27d57df0-0794-4e96-92ac-85b802200864	96b17d9f-be1f-482f-bd8c-2766c182a4a5	0	10	f	\N	\N
49092357-173d-4e95-9a86-7d595b5eeccb	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	96b17d9f-be1f-482f-bd8c-2766c182a4a5	1	20	t	db9fb3da-7bc6-4991-9d6b-ccd4ed1dea2c	\N
99938299-de46-40aa-b8e0-5d5fd8dbaf16	\N	registration-page-form	27d57df0-0794-4e96-92ac-85b802200864	0ee368dd-05b2-44d8-9b53-f7c3dbc06dd8	0	10	t	21ba39fa-d45d-4c4e-8be4-6a5c4bbbd4ed	\N
eaf4be15-0bf3-4859-a730-68b247b0ba4e	\N	registration-user-creation	27d57df0-0794-4e96-92ac-85b802200864	21ba39fa-d45d-4c4e-8be4-6a5c4bbbd4ed	0	20	f	\N	\N
abb6e390-0aed-49e0-ad0b-fdbeedd4f96d	\N	registration-password-action	27d57df0-0794-4e96-92ac-85b802200864	21ba39fa-d45d-4c4e-8be4-6a5c4bbbd4ed	0	50	f	\N	\N
1bae39b7-3aee-4f23-a59b-4c34da91fcba	\N	registration-recaptcha-action	27d57df0-0794-4e96-92ac-85b802200864	21ba39fa-d45d-4c4e-8be4-6a5c4bbbd4ed	3	60	f	\N	\N
cb3d18d0-1570-4881-bf01-7806b9ad0b9d	\N	registration-terms-and-conditions	27d57df0-0794-4e96-92ac-85b802200864	21ba39fa-d45d-4c4e-8be4-6a5c4bbbd4ed	3	70	f	\N	\N
14e14ad2-8dbc-4989-af13-94eb3c903fdb	\N	reset-credentials-choose-user	27d57df0-0794-4e96-92ac-85b802200864	d3394390-d4bc-4df5-88ed-4f1665e4e780	0	10	f	\N	\N
e122522e-228f-47f3-8c60-30ad7d992cf8	\N	reset-credential-email	27d57df0-0794-4e96-92ac-85b802200864	d3394390-d4bc-4df5-88ed-4f1665e4e780	0	20	f	\N	\N
bca5b16c-5526-4f51-b95f-5442fec83854	\N	reset-password	27d57df0-0794-4e96-92ac-85b802200864	d3394390-d4bc-4df5-88ed-4f1665e4e780	0	30	f	\N	\N
57a5c2e8-2b12-4b72-b8d3-81c92873286a	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	d3394390-d4bc-4df5-88ed-4f1665e4e780	1	40	t	66027234-9ca9-4325-b797-16ae7ce65bb1	\N
35b72453-6dd9-4c25-bd95-86b76f5e0245	\N	http-basic-authenticator	27d57df0-0794-4e96-92ac-85b802200864	bf6e18d5-a92d-42ef-bd7e-8a460bf8f732	0	10	f	\N	\N
\.


--
-- Data for Name: authentication_flow; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.authentication_flow (id, alias, description, realm_id, provider_id, top_level, built_in) FROM stdin;
88720b08-0957-4146-9ac9-60ffcb0cf8c0	browser	Browser based authentication	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	t	t
39a77907-ba51-43af-a6c2-74e0ba82da0e	forms	Username, password, otp and other auth forms.	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
c2a9714b-58b4-47fe-b507-1194ab67b237	Browser - Conditional 2FA	Flow to determine if any 2FA is required for the authentication	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
c142818d-e1c3-4984-bcd6-668e0e7b5c9a	direct grant	OpenID Connect Resource Owner Grant	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	t	t
ddefde89-5a92-4028-a559-1df859bc2595	Direct Grant - Conditional OTP	Flow to determine if the OTP is required for the authentication	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
20508aef-657a-438f-8d43-7246a41916bc	registration	Registration flow	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	t	t
8c62e418-6a46-4341-a670-154739492ed9	registration form	Registration form	955a00d0-1411-4e86-8ef2-bdedffd7a66f	form-flow	f	t
52ecf8dd-e190-4618-b195-ad7ef4bac05e	reset credentials	Reset credentials for a user if they forgot their password or something	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	t	t
0dd7935e-3ba1-4bf5-95df-c5e0c5db5b6d	Reset - Conditional OTP	Flow to determine if the OTP should be reset or not. Set to REQUIRED to force.	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
a4982cc5-a485-4514-b1b9-cde6b785f8e3	clients	Base authentication for clients	955a00d0-1411-4e86-8ef2-bdedffd7a66f	client-flow	t	t
c77a8f72-35a6-4abe-b855-546a1c7ec8f6	first broker login	Actions taken after first broker login with identity provider account, which is not yet linked to any Keycloak account	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	t	t
92968cf4-9f76-4561-992f-53c5cf405c69	User creation or linking	Flow for the existing/non-existing user alternatives	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
74700261-852e-4c32-827d-7365d40dd33d	Handle Existing Account	Handle what to do if there is existing account with same email/username like authenticated identity provider	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
2b7cb72d-9935-48d0-97ce-8ec91a80ae94	Account verification options	Method with which to verity the existing account	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
143d1334-40f2-454f-a53f-b49426e700bc	Verify Existing Account by Re-authentication	Reauthentication of existing account	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
03be9617-a7ff-40aa-a845-41011b6fcf44	First broker login - Conditional 2FA	Flow to determine if any 2FA is required for the authentication	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	f	t
26460c35-458c-49b7-9f44-638c28923896	saml ecp	SAML ECP Profile Authentication Flow	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	t	t
bc147e2e-9c46-4f64-938c-5b0c54b8e2d2	docker auth	Used by Docker clients to authenticate against the IDP	955a00d0-1411-4e86-8ef2-bdedffd7a66f	basic-flow	t	t
0662e4c9-15cc-4b92-88d5-a4d544134f4a	Account verification options	Method with which to verity the existing account	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
db9fb3da-7bc6-4991-9d6b-ccd4ed1dea2c	Browser - Conditional OTP	Flow to determine if the OTP is required for the authentication	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
87ae6868-baec-4183-9138-7b960892e64d	Browser - Conditional Organization	Flow to determine if the organization identity-first login is to be used	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
87cc3ca5-16a1-4fe8-9593-9fa0ae5023d6	Direct Grant - Conditional OTP	Flow to determine if the OTP is required for the authentication	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
6cf3eca2-86b4-4ef8-b99d-2fbc5e7032e9	First Broker Login - Conditional Organization	Flow to determine if the authenticator that adds organization members is to be used	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
317b2bbe-bb7b-4b21-b1d1-c8b64af88058	First broker login - Conditional OTP	Flow to determine if the OTP is required for the authentication	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
f81eb67b-c68d-4e7d-b569-64e525d013f3	Handle Existing Account	Handle what to do if there is existing account with same email/username like authenticated identity provider	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
f6a078df-b8d0-46fd-bdeb-016bf0f39098	Organization	\N	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
66027234-9ca9-4325-b797-16ae7ce65bb1	Reset - Conditional OTP	Flow to determine if the OTP should be reset or not. Set to REQUIRED to force.	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
a02ab114-ddc5-42cf-8c0f-0836ec2081f8	User creation or linking	Flow for the existing/non-existing user alternatives	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
b581c880-e14c-43b8-aa4b-d535a4158307	Verify Existing Account by Re-authentication	Reauthentication of existing account	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
11c1887b-aef0-4eb9-a262-e1222b430dcf	browser	Browser based authentication	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	t	t
08839456-c079-4f3d-8dd9-64e924cd83cd	clients	Base authentication for clients	27d57df0-0794-4e96-92ac-85b802200864	client-flow	t	t
e282ad24-f7b9-4537-a897-55ffae46f8a8	direct grant	OpenID Connect Resource Owner Grant	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	t	t
10c92f67-3d8c-49c3-8f88-acebd3ca9d0c	docker auth	Used by Docker clients to authenticate against the IDP	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	t	t
b90b5d9b-cbdc-4b9f-b90d-881cf34c943d	first broker login	Actions taken after first broker login with identity provider account, which is not yet linked to any Keycloak account	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	t	t
96b17d9f-be1f-482f-bd8c-2766c182a4a5	forms	Username, password, otp and other auth forms.	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	f	t
0ee368dd-05b2-44d8-9b53-f7c3dbc06dd8	registration	Registration flow	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	t	t
21ba39fa-d45d-4c4e-8be4-6a5c4bbbd4ed	registration form	Registration form	27d57df0-0794-4e96-92ac-85b802200864	form-flow	f	t
d3394390-d4bc-4df5-88ed-4f1665e4e780	reset credentials	Reset credentials for a user if they forgot their password or something	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	t	t
bf6e18d5-a92d-42ef-bd7e-8a460bf8f732	saml ecp	SAML ECP Profile Authentication Flow	27d57df0-0794-4e96-92ac-85b802200864	basic-flow	t	t
\.


--
-- Data for Name: authenticator_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.authenticator_config (id, alias, realm_id) FROM stdin;
2cd6a5ea-63e8-4529-98fe-da89813e6372	browser-conditional-credential	955a00d0-1411-4e86-8ef2-bdedffd7a66f
e5668454-2827-4f0c-960f-7ea567dc9e35	review profile config	955a00d0-1411-4e86-8ef2-bdedffd7a66f
848e350e-7a9d-4301-9d03-a82acbd9ca23	create unique user config	955a00d0-1411-4e86-8ef2-bdedffd7a66f
94b653df-682f-41d7-b2b0-fdb9186fd568	first-broker-login-conditional-credential	955a00d0-1411-4e86-8ef2-bdedffd7a66f
f34eb683-7dca-4a52-9ec2-077f35f3a8ce	create unique user config	27d57df0-0794-4e96-92ac-85b802200864
15d09fdd-c8c7-4ce2-8a6c-242e74d97618	review profile config	27d57df0-0794-4e96-92ac-85b802200864
\.


--
-- Data for Name: authenticator_config_entry; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.authenticator_config_entry (authenticator_id, value, name) FROM stdin;
2cd6a5ea-63e8-4529-98fe-da89813e6372	webauthn-passwordless	credentials
848e350e-7a9d-4301-9d03-a82acbd9ca23	false	require.password.update.after.registration
94b653df-682f-41d7-b2b0-fdb9186fd568	webauthn-passwordless	credentials
e5668454-2827-4f0c-960f-7ea567dc9e35	missing	update.profile.on.first.login
15d09fdd-c8c7-4ce2-8a6c-242e74d97618	missing	update.profile.on.first.login
f34eb683-7dca-4a52-9ec2-077f35f3a8ce	false	require.password.update.after.registration
\.


--
-- Data for Name: broker_link; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.broker_link (identity_provider, storage_provider_id, realm_id, broker_user_id, broker_username, token, user_id) FROM stdin;
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client (id, enabled, full_scope_allowed, client_id, not_before, public_client, secret, base_url, bearer_only, management_url, surrogate_auth_required, realm_id, protocol, node_rereg_timeout, frontchannel_logout, consent_required, name, service_accounts_enabled, client_authenticator_type, root_url, description, registration_token, standard_flow_enabled, implicit_flow_enabled, direct_access_grants_enabled, always_display_in_console) FROM stdin;
aeb1d986-2bef-405c-a65d-c190561c2f31	t	f	master-realm	0	f	\N	\N	t	\N	f	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N	0	f	f	master Realm	f	client-secret	\N	\N	\N	t	f	f	f
0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	f	account	0	t	\N	/realms/master/account/	f	\N	f	955a00d0-1411-4e86-8ef2-bdedffd7a66f	openid-connect	0	f	f	${client_account}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
acf59302-35a1-4e76-895c-f9a9c7234692	t	f	account-console	0	t	\N	/realms/master/account/	f	\N	f	955a00d0-1411-4e86-8ef2-bdedffd7a66f	openid-connect	0	f	f	${client_account-console}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
021ad7d4-8c07-4560-932f-356c274b52f3	t	f	broker	0	f	\N	\N	t	\N	f	955a00d0-1411-4e86-8ef2-bdedffd7a66f	openid-connect	0	f	f	${client_broker}	f	client-secret	\N	\N	\N	t	f	f	f
247c0e1e-e295-45ea-904d-824e58645759	t	t	security-admin-console	0	t	\N	/admin/master/console/	f	\N	f	955a00d0-1411-4e86-8ef2-bdedffd7a66f	openid-connect	0	f	f	${client_security-admin-console}	f	client-secret	${authAdminUrl}	\N	\N	t	f	f	f
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	t	t	admin-cli	0	t	\N	\N	f	\N	f	955a00d0-1411-4e86-8ef2-bdedffd7a66f	openid-connect	0	f	f	${client_admin-cli}	f	client-secret	\N	\N	\N	f	f	t	f
1516ec14-8f75-485c-82c7-0df5c1d360d1	t	f	FHIR-Auth-realm	0	f	\N	\N	t	\N	f	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N	0	f	f	FHIR-Auth Realm	f	client-secret	\N	\N	\N	t	f	f	f
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	f	account	0	t	\N	/realms/FHIR-Auth/account/	f	\N	f	27d57df0-0794-4e96-92ac-85b802200864	openid-connect	0	f	f	${client_account}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
157e8078-530f-467a-9072-46f2ea6627fb	t	f	account-console	0	t	\N	/realms/FHIR-Auth/account/	f	\N	f	27d57df0-0794-4e96-92ac-85b802200864	openid-connect	0	f	f	${client_account-console}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
1f8ae50c-d35f-438d-b919-a0021c67beea	t	t	admin-cli	0	t	\N	\N	f	\N	f	27d57df0-0794-4e96-92ac-85b802200864	openid-connect	0	f	f	${client_admin-cli}	f	client-secret	\N	\N	\N	f	f	t	f
a6df953f-60f9-46b6-83d9-0a81b62d04a5	t	f	broker	0	f	\N	\N	t	\N	f	27d57df0-0794-4e96-92ac-85b802200864	openid-connect	0	f	f	${client_broker}	f	client-secret	\N	\N	\N	t	f	f	f
f637d925-d634-4b92-ad79-fb1b387b3e2e	t	t	fhir-client	0	f	QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP		f	http://localhost:8080	f	27d57df0-0794-4e96-92ac-85b802200864	openid-connect	-1	t	f	FHIR Client	t	client-secret	http://localhost:8080	Client für FHIR-Ressourcen	\N	t	f	t	f
c1926955-f77b-4a15-8be9-fbab2b1f504f	t	f	realm-management	0	f	\N	\N	t	\N	f	27d57df0-0794-4e96-92ac-85b802200864	openid-connect	0	f	f	${client_realm-management}	f	client-secret	\N	\N	\N	t	f	f	f
60c887d6-2ce7-4fe9-98f0-fe2625266194	t	t	security-admin-console	0	t	\N	/admin/FHIR-Auth/console/	f	\N	f	27d57df0-0794-4e96-92ac-85b802200864	openid-connect	0	f	f	${client_security-admin-console}	f	client-secret	${authAdminUrl}	\N	\N	t	f	f	f
\.


--
-- Data for Name: client_attributes; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_attributes (client_id, name, value) FROM stdin;
0f0ec0f5-6e68-4308-8b92-25489a9feacf	post.logout.redirect.uris	+
acf59302-35a1-4e76-895c-f9a9c7234692	post.logout.redirect.uris	+
acf59302-35a1-4e76-895c-f9a9c7234692	pkce.code.challenge.method	S256
247c0e1e-e295-45ea-904d-824e58645759	post.logout.redirect.uris	+
247c0e1e-e295-45ea-904d-824e58645759	pkce.code.challenge.method	S256
247c0e1e-e295-45ea-904d-824e58645759	client.use.lightweight.access.token.enabled	true
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	client.use.lightweight.access.token.enabled	true
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	realm_client	false
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	post.logout.redirect.uris	+
157e8078-530f-467a-9072-46f2ea6627fb	realm_client	false
157e8078-530f-467a-9072-46f2ea6627fb	post.logout.redirect.uris	+
157e8078-530f-467a-9072-46f2ea6627fb	pkce.code.challenge.method	S256
1f8ae50c-d35f-438d-b919-a0021c67beea	realm_client	false
1f8ae50c-d35f-438d-b919-a0021c67beea	client.use.lightweight.access.token.enabled	true
1f8ae50c-d35f-438d-b919-a0021c67beea	post.logout.redirect.uris	+
a6df953f-60f9-46b6-83d9-0a81b62d04a5	realm_client	true
a6df953f-60f9-46b6-83d9-0a81b62d04a5	post.logout.redirect.uris	+
f637d925-d634-4b92-ad79-fb1b387b3e2e	realm_client	false
f637d925-d634-4b92-ad79-fb1b387b3e2e	oidc.ciba.grant.enabled	false
f637d925-d634-4b92-ad79-fb1b387b3e2e	client.secret.creation.time	1762203061
f637d925-d634-4b92-ad79-fb1b387b3e2e	backchannel.logout.session.required	true
f637d925-d634-4b92-ad79-fb1b387b3e2e	post.logout.redirect.uris	http://localhost:8080/
f637d925-d634-4b92-ad79-fb1b387b3e2e	oauth2.device.authorization.grant.enabled	false
f637d925-d634-4b92-ad79-fb1b387b3e2e	display.on.consent.screen	false
f637d925-d634-4b92-ad79-fb1b387b3e2e	backchannel.logout.revoke.offline.tokens	false
c1926955-f77b-4a15-8be9-fbab2b1f504f	realm_client	true
c1926955-f77b-4a15-8be9-fbab2b1f504f	post.logout.redirect.uris	+
60c887d6-2ce7-4fe9-98f0-fe2625266194	realm_client	false
60c887d6-2ce7-4fe9-98f0-fe2625266194	client.use.lightweight.access.token.enabled	true
60c887d6-2ce7-4fe9-98f0-fe2625266194	post.logout.redirect.uris	+
60c887d6-2ce7-4fe9-98f0-fe2625266194	pkce.code.challenge.method	S256
\.


--
-- Data for Name: client_auth_flow_bindings; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_auth_flow_bindings (client_id, flow_id, binding_name) FROM stdin;
\.


--
-- Data for Name: client_initial_access; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_initial_access (id, realm_id, "timestamp", expiration, count, remaining_count) FROM stdin;
\.


--
-- Data for Name: client_node_registrations; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_node_registrations (client_id, value, name) FROM stdin;
\.


--
-- Data for Name: client_scope; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_scope (id, name, realm_id, description, protocol) FROM stdin;
17958855-2814-4159-b3a1-5b40cdaeebe6	offline_access	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect built-in scope: offline_access	openid-connect
3e34312e-2989-4347-a934-b60dfd2d544c	role_list	955a00d0-1411-4e86-8ef2-bdedffd7a66f	SAML role list	saml
6e404f54-922f-4145-bb29-a9e21a8edcf9	saml_organization	955a00d0-1411-4e86-8ef2-bdedffd7a66f	Organization Membership	saml
77258524-6f0f-4406-b315-7ddc4796c00d	profile	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect built-in scope: profile	openid-connect
653a25e7-40d9-4b92-a25e-bb8455b6ebdf	email	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect built-in scope: email	openid-connect
40d8effa-ea43-4033-a14c-357a47b72d7c	address	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect built-in scope: address	openid-connect
d8c9cf61-7cc8-4290-89b2-ab17995ff99d	phone	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect built-in scope: phone	openid-connect
086a4221-efa4-40b1-9f46-97e5d68fdf20	roles	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect scope for add user roles to the access token	openid-connect
61816b49-1207-4d27-852b-b14874c5eddf	web-origins	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect scope for add allowed web origins to the access token	openid-connect
84a15d18-e232-4be0-86ea-3458c0dab9b3	microprofile-jwt	955a00d0-1411-4e86-8ef2-bdedffd7a66f	Microprofile - JWT built-in scope	openid-connect
a8cefe79-91a3-45ea-b561-5aff65223896	acr	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect scope for add acr (authentication context class reference) to the token	openid-connect
30aca326-0e4f-4226-bfa0-a7c546848c95	basic	955a00d0-1411-4e86-8ef2-bdedffd7a66f	OpenID Connect scope for add all basic claims to the token	openid-connect
7cf38aa1-6d16-4883-bd8b-84126e385179	service_account	955a00d0-1411-4e86-8ef2-bdedffd7a66f	Specific scope for a client enabled for service accounts	openid-connect
d3507a8a-46c0-4ae7-9011-fc52c5207e07	organization	955a00d0-1411-4e86-8ef2-bdedffd7a66f	Additional claims about the organization a subject belongs to	openid-connect
38b9f19b-48c5-49f2-a73f-07a8404f2c48	web-origins	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect scope for add allowed web origins to the access token	openid-connect
67bc1745-9981-4d04-88a8-871d88a7e522	role_list	27d57df0-0794-4e96-92ac-85b802200864	SAML role list	saml
5b61aded-f5c8-4ad3-b779-065520195daa	phone	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect built-in scope: phone	openid-connect
d512f187-3acb-4f8a-a985-41a797d3e53f	offline_access	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect built-in scope: offline_access	openid-connect
364cdea3-6979-46a0-85f1-222797349de4	address	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect built-in scope: address	openid-connect
54b31ac9-dea0-43d0-aa3a-1f691b495492	organization	27d57df0-0794-4e96-92ac-85b802200864	Additional claims about the organization a subject belongs to	openid-connect
df6a0a58-c6a8-4534-83b1-7b52b3aa62f9	saml_organization	27d57df0-0794-4e96-92ac-85b802200864	Organization Membership	saml
147f68f2-1deb-489e-90c1-1f0a216aca17	roles	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect scope for add user roles to the access token	openid-connect
c87139e6-dacf-4a3b-ab0e-c74899e16e31	basic	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect scope for add all basic claims to the token	openid-connect
3f34b32f-25ee-4770-979c-918b005c06c6	microprofile-jwt	27d57df0-0794-4e96-92ac-85b802200864	Microprofile - JWT built-in scope	openid-connect
2f4c6846-d426-4d40-a15f-1acd7351a946	acr	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect scope for add acr (authentication context class reference) to the token	openid-connect
fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	profile	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect built-in scope: profile	openid-connect
1d2bd933-a550-4d11-aa78-258954290a9c	email	27d57df0-0794-4e96-92ac-85b802200864	OpenID Connect built-in scope: email	openid-connect
9737a927-f817-4a2b-849f-e86ee0537138	service_account	27d57df0-0794-4e96-92ac-85b802200864	Specific scope for a client enabled for service accounts	openid-connect
\.


--
-- Data for Name: client_scope_attributes; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_scope_attributes (scope_id, value, name) FROM stdin;
17958855-2814-4159-b3a1-5b40cdaeebe6	true	display.on.consent.screen
17958855-2814-4159-b3a1-5b40cdaeebe6	${offlineAccessScopeConsentText}	consent.screen.text
3e34312e-2989-4347-a934-b60dfd2d544c	true	display.on.consent.screen
3e34312e-2989-4347-a934-b60dfd2d544c	${samlRoleListScopeConsentText}	consent.screen.text
6e404f54-922f-4145-bb29-a9e21a8edcf9	false	display.on.consent.screen
77258524-6f0f-4406-b315-7ddc4796c00d	true	display.on.consent.screen
77258524-6f0f-4406-b315-7ddc4796c00d	${profileScopeConsentText}	consent.screen.text
77258524-6f0f-4406-b315-7ddc4796c00d	true	include.in.token.scope
653a25e7-40d9-4b92-a25e-bb8455b6ebdf	true	display.on.consent.screen
653a25e7-40d9-4b92-a25e-bb8455b6ebdf	${emailScopeConsentText}	consent.screen.text
653a25e7-40d9-4b92-a25e-bb8455b6ebdf	true	include.in.token.scope
40d8effa-ea43-4033-a14c-357a47b72d7c	true	display.on.consent.screen
40d8effa-ea43-4033-a14c-357a47b72d7c	${addressScopeConsentText}	consent.screen.text
40d8effa-ea43-4033-a14c-357a47b72d7c	true	include.in.token.scope
d8c9cf61-7cc8-4290-89b2-ab17995ff99d	true	display.on.consent.screen
d8c9cf61-7cc8-4290-89b2-ab17995ff99d	${phoneScopeConsentText}	consent.screen.text
d8c9cf61-7cc8-4290-89b2-ab17995ff99d	true	include.in.token.scope
086a4221-efa4-40b1-9f46-97e5d68fdf20	true	display.on.consent.screen
086a4221-efa4-40b1-9f46-97e5d68fdf20	${rolesScopeConsentText}	consent.screen.text
086a4221-efa4-40b1-9f46-97e5d68fdf20	false	include.in.token.scope
61816b49-1207-4d27-852b-b14874c5eddf	false	display.on.consent.screen
61816b49-1207-4d27-852b-b14874c5eddf		consent.screen.text
61816b49-1207-4d27-852b-b14874c5eddf	false	include.in.token.scope
84a15d18-e232-4be0-86ea-3458c0dab9b3	false	display.on.consent.screen
84a15d18-e232-4be0-86ea-3458c0dab9b3	true	include.in.token.scope
a8cefe79-91a3-45ea-b561-5aff65223896	false	display.on.consent.screen
a8cefe79-91a3-45ea-b561-5aff65223896	false	include.in.token.scope
30aca326-0e4f-4226-bfa0-a7c546848c95	false	display.on.consent.screen
30aca326-0e4f-4226-bfa0-a7c546848c95	false	include.in.token.scope
7cf38aa1-6d16-4883-bd8b-84126e385179	false	display.on.consent.screen
7cf38aa1-6d16-4883-bd8b-84126e385179	false	include.in.token.scope
d3507a8a-46c0-4ae7-9011-fc52c5207e07	true	display.on.consent.screen
d3507a8a-46c0-4ae7-9011-fc52c5207e07	${organizationScopeConsentText}	consent.screen.text
d3507a8a-46c0-4ae7-9011-fc52c5207e07	true	include.in.token.scope
38b9f19b-48c5-49f2-a73f-07a8404f2c48	false	include.in.token.scope
38b9f19b-48c5-49f2-a73f-07a8404f2c48		consent.screen.text
38b9f19b-48c5-49f2-a73f-07a8404f2c48	false	display.on.consent.screen
67bc1745-9981-4d04-88a8-871d88a7e522	${samlRoleListScopeConsentText}	consent.screen.text
67bc1745-9981-4d04-88a8-871d88a7e522	true	display.on.consent.screen
5b61aded-f5c8-4ad3-b779-065520195daa	true	include.in.token.scope
5b61aded-f5c8-4ad3-b779-065520195daa	${phoneScopeConsentText}	consent.screen.text
5b61aded-f5c8-4ad3-b779-065520195daa	true	display.on.consent.screen
d512f187-3acb-4f8a-a985-41a797d3e53f	${offlineAccessScopeConsentText}	consent.screen.text
d512f187-3acb-4f8a-a985-41a797d3e53f	true	display.on.consent.screen
364cdea3-6979-46a0-85f1-222797349de4	true	include.in.token.scope
364cdea3-6979-46a0-85f1-222797349de4	${addressScopeConsentText}	consent.screen.text
364cdea3-6979-46a0-85f1-222797349de4	true	display.on.consent.screen
54b31ac9-dea0-43d0-aa3a-1f691b495492	true	include.in.token.scope
54b31ac9-dea0-43d0-aa3a-1f691b495492	${organizationScopeConsentText}	consent.screen.text
54b31ac9-dea0-43d0-aa3a-1f691b495492	true	display.on.consent.screen
df6a0a58-c6a8-4534-83b1-7b52b3aa62f9	false	display.on.consent.screen
147f68f2-1deb-489e-90c1-1f0a216aca17	false	include.in.token.scope
147f68f2-1deb-489e-90c1-1f0a216aca17	${rolesScopeConsentText}	consent.screen.text
147f68f2-1deb-489e-90c1-1f0a216aca17	true	display.on.consent.screen
c87139e6-dacf-4a3b-ab0e-c74899e16e31	false	include.in.token.scope
c87139e6-dacf-4a3b-ab0e-c74899e16e31	false	display.on.consent.screen
3f34b32f-25ee-4770-979c-918b005c06c6	true	include.in.token.scope
3f34b32f-25ee-4770-979c-918b005c06c6	false	display.on.consent.screen
2f4c6846-d426-4d40-a15f-1acd7351a946	false	include.in.token.scope
2f4c6846-d426-4d40-a15f-1acd7351a946	false	display.on.consent.screen
fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	true	include.in.token.scope
fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	${profileScopeConsentText}	consent.screen.text
fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	true	display.on.consent.screen
1d2bd933-a550-4d11-aa78-258954290a9c	true	include.in.token.scope
1d2bd933-a550-4d11-aa78-258954290a9c	${emailScopeConsentText}	consent.screen.text
1d2bd933-a550-4d11-aa78-258954290a9c	true	display.on.consent.screen
9737a927-f817-4a2b-849f-e86ee0537138	false	display.on.consent.screen
9737a927-f817-4a2b-849f-e86ee0537138	false	include.in.token.scope
\.


--
-- Data for Name: client_scope_client; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_scope_client (client_id, scope_id, default_scope) FROM stdin;
0f0ec0f5-6e68-4308-8b92-25489a9feacf	61816b49-1207-4d27-852b-b14874c5eddf	t
0f0ec0f5-6e68-4308-8b92-25489a9feacf	30aca326-0e4f-4226-bfa0-a7c546848c95	t
0f0ec0f5-6e68-4308-8b92-25489a9feacf	653a25e7-40d9-4b92-a25e-bb8455b6ebdf	t
0f0ec0f5-6e68-4308-8b92-25489a9feacf	a8cefe79-91a3-45ea-b561-5aff65223896	t
0f0ec0f5-6e68-4308-8b92-25489a9feacf	086a4221-efa4-40b1-9f46-97e5d68fdf20	t
0f0ec0f5-6e68-4308-8b92-25489a9feacf	77258524-6f0f-4406-b315-7ddc4796c00d	t
0f0ec0f5-6e68-4308-8b92-25489a9feacf	84a15d18-e232-4be0-86ea-3458c0dab9b3	f
0f0ec0f5-6e68-4308-8b92-25489a9feacf	d8c9cf61-7cc8-4290-89b2-ab17995ff99d	f
0f0ec0f5-6e68-4308-8b92-25489a9feacf	17958855-2814-4159-b3a1-5b40cdaeebe6	f
0f0ec0f5-6e68-4308-8b92-25489a9feacf	40d8effa-ea43-4033-a14c-357a47b72d7c	f
0f0ec0f5-6e68-4308-8b92-25489a9feacf	d3507a8a-46c0-4ae7-9011-fc52c5207e07	f
acf59302-35a1-4e76-895c-f9a9c7234692	61816b49-1207-4d27-852b-b14874c5eddf	t
acf59302-35a1-4e76-895c-f9a9c7234692	30aca326-0e4f-4226-bfa0-a7c546848c95	t
acf59302-35a1-4e76-895c-f9a9c7234692	653a25e7-40d9-4b92-a25e-bb8455b6ebdf	t
acf59302-35a1-4e76-895c-f9a9c7234692	a8cefe79-91a3-45ea-b561-5aff65223896	t
acf59302-35a1-4e76-895c-f9a9c7234692	086a4221-efa4-40b1-9f46-97e5d68fdf20	t
acf59302-35a1-4e76-895c-f9a9c7234692	77258524-6f0f-4406-b315-7ddc4796c00d	t
acf59302-35a1-4e76-895c-f9a9c7234692	84a15d18-e232-4be0-86ea-3458c0dab9b3	f
acf59302-35a1-4e76-895c-f9a9c7234692	d8c9cf61-7cc8-4290-89b2-ab17995ff99d	f
acf59302-35a1-4e76-895c-f9a9c7234692	17958855-2814-4159-b3a1-5b40cdaeebe6	f
acf59302-35a1-4e76-895c-f9a9c7234692	40d8effa-ea43-4033-a14c-357a47b72d7c	f
acf59302-35a1-4e76-895c-f9a9c7234692	d3507a8a-46c0-4ae7-9011-fc52c5207e07	f
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	61816b49-1207-4d27-852b-b14874c5eddf	t
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	30aca326-0e4f-4226-bfa0-a7c546848c95	t
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	653a25e7-40d9-4b92-a25e-bb8455b6ebdf	t
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	a8cefe79-91a3-45ea-b561-5aff65223896	t
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	086a4221-efa4-40b1-9f46-97e5d68fdf20	t
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	77258524-6f0f-4406-b315-7ddc4796c00d	t
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	84a15d18-e232-4be0-86ea-3458c0dab9b3	f
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	d8c9cf61-7cc8-4290-89b2-ab17995ff99d	f
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	17958855-2814-4159-b3a1-5b40cdaeebe6	f
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	40d8effa-ea43-4033-a14c-357a47b72d7c	f
2ccb53ba-e61f-4f11-bed1-1efcf972e5ef	d3507a8a-46c0-4ae7-9011-fc52c5207e07	f
021ad7d4-8c07-4560-932f-356c274b52f3	61816b49-1207-4d27-852b-b14874c5eddf	t
021ad7d4-8c07-4560-932f-356c274b52f3	30aca326-0e4f-4226-bfa0-a7c546848c95	t
021ad7d4-8c07-4560-932f-356c274b52f3	653a25e7-40d9-4b92-a25e-bb8455b6ebdf	t
021ad7d4-8c07-4560-932f-356c274b52f3	a8cefe79-91a3-45ea-b561-5aff65223896	t
021ad7d4-8c07-4560-932f-356c274b52f3	086a4221-efa4-40b1-9f46-97e5d68fdf20	t
021ad7d4-8c07-4560-932f-356c274b52f3	77258524-6f0f-4406-b315-7ddc4796c00d	t
021ad7d4-8c07-4560-932f-356c274b52f3	84a15d18-e232-4be0-86ea-3458c0dab9b3	f
021ad7d4-8c07-4560-932f-356c274b52f3	d8c9cf61-7cc8-4290-89b2-ab17995ff99d	f
021ad7d4-8c07-4560-932f-356c274b52f3	17958855-2814-4159-b3a1-5b40cdaeebe6	f
021ad7d4-8c07-4560-932f-356c274b52f3	40d8effa-ea43-4033-a14c-357a47b72d7c	f
021ad7d4-8c07-4560-932f-356c274b52f3	d3507a8a-46c0-4ae7-9011-fc52c5207e07	f
aeb1d986-2bef-405c-a65d-c190561c2f31	61816b49-1207-4d27-852b-b14874c5eddf	t
aeb1d986-2bef-405c-a65d-c190561c2f31	30aca326-0e4f-4226-bfa0-a7c546848c95	t
aeb1d986-2bef-405c-a65d-c190561c2f31	653a25e7-40d9-4b92-a25e-bb8455b6ebdf	t
aeb1d986-2bef-405c-a65d-c190561c2f31	a8cefe79-91a3-45ea-b561-5aff65223896	t
aeb1d986-2bef-405c-a65d-c190561c2f31	086a4221-efa4-40b1-9f46-97e5d68fdf20	t
aeb1d986-2bef-405c-a65d-c190561c2f31	77258524-6f0f-4406-b315-7ddc4796c00d	t
aeb1d986-2bef-405c-a65d-c190561c2f31	84a15d18-e232-4be0-86ea-3458c0dab9b3	f
aeb1d986-2bef-405c-a65d-c190561c2f31	d8c9cf61-7cc8-4290-89b2-ab17995ff99d	f
aeb1d986-2bef-405c-a65d-c190561c2f31	17958855-2814-4159-b3a1-5b40cdaeebe6	f
aeb1d986-2bef-405c-a65d-c190561c2f31	40d8effa-ea43-4033-a14c-357a47b72d7c	f
aeb1d986-2bef-405c-a65d-c190561c2f31	d3507a8a-46c0-4ae7-9011-fc52c5207e07	f
247c0e1e-e295-45ea-904d-824e58645759	61816b49-1207-4d27-852b-b14874c5eddf	t
247c0e1e-e295-45ea-904d-824e58645759	30aca326-0e4f-4226-bfa0-a7c546848c95	t
247c0e1e-e295-45ea-904d-824e58645759	653a25e7-40d9-4b92-a25e-bb8455b6ebdf	t
247c0e1e-e295-45ea-904d-824e58645759	a8cefe79-91a3-45ea-b561-5aff65223896	t
247c0e1e-e295-45ea-904d-824e58645759	086a4221-efa4-40b1-9f46-97e5d68fdf20	t
247c0e1e-e295-45ea-904d-824e58645759	77258524-6f0f-4406-b315-7ddc4796c00d	t
247c0e1e-e295-45ea-904d-824e58645759	84a15d18-e232-4be0-86ea-3458c0dab9b3	f
247c0e1e-e295-45ea-904d-824e58645759	d8c9cf61-7cc8-4290-89b2-ab17995ff99d	f
247c0e1e-e295-45ea-904d-824e58645759	17958855-2814-4159-b3a1-5b40cdaeebe6	f
247c0e1e-e295-45ea-904d-824e58645759	40d8effa-ea43-4033-a14c-357a47b72d7c	f
247c0e1e-e295-45ea-904d-824e58645759	d3507a8a-46c0-4ae7-9011-fc52c5207e07	f
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	2f4c6846-d426-4d40-a15f-1acd7351a946	t
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	1d2bd933-a550-4d11-aa78-258954290a9c	t
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	147f68f2-1deb-489e-90c1-1f0a216aca17	t
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	5b61aded-f5c8-4ad3-b779-065520195daa	f
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	d512f187-3acb-4f8a-a985-41a797d3e53f	f
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	3f34b32f-25ee-4770-979c-918b005c06c6	f
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	364cdea3-6979-46a0-85f1-222797349de4	f
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
157e8078-530f-467a-9072-46f2ea6627fb	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
157e8078-530f-467a-9072-46f2ea6627fb	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
157e8078-530f-467a-9072-46f2ea6627fb	2f4c6846-d426-4d40-a15f-1acd7351a946	t
157e8078-530f-467a-9072-46f2ea6627fb	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
157e8078-530f-467a-9072-46f2ea6627fb	1d2bd933-a550-4d11-aa78-258954290a9c	t
157e8078-530f-467a-9072-46f2ea6627fb	147f68f2-1deb-489e-90c1-1f0a216aca17	t
157e8078-530f-467a-9072-46f2ea6627fb	5b61aded-f5c8-4ad3-b779-065520195daa	f
157e8078-530f-467a-9072-46f2ea6627fb	d512f187-3acb-4f8a-a985-41a797d3e53f	f
157e8078-530f-467a-9072-46f2ea6627fb	3f34b32f-25ee-4770-979c-918b005c06c6	f
157e8078-530f-467a-9072-46f2ea6627fb	364cdea3-6979-46a0-85f1-222797349de4	f
157e8078-530f-467a-9072-46f2ea6627fb	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
1f8ae50c-d35f-438d-b919-a0021c67beea	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
1f8ae50c-d35f-438d-b919-a0021c67beea	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
1f8ae50c-d35f-438d-b919-a0021c67beea	2f4c6846-d426-4d40-a15f-1acd7351a946	t
1f8ae50c-d35f-438d-b919-a0021c67beea	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
1f8ae50c-d35f-438d-b919-a0021c67beea	1d2bd933-a550-4d11-aa78-258954290a9c	t
1f8ae50c-d35f-438d-b919-a0021c67beea	147f68f2-1deb-489e-90c1-1f0a216aca17	t
1f8ae50c-d35f-438d-b919-a0021c67beea	5b61aded-f5c8-4ad3-b779-065520195daa	f
1f8ae50c-d35f-438d-b919-a0021c67beea	d512f187-3acb-4f8a-a985-41a797d3e53f	f
1f8ae50c-d35f-438d-b919-a0021c67beea	3f34b32f-25ee-4770-979c-918b005c06c6	f
1f8ae50c-d35f-438d-b919-a0021c67beea	364cdea3-6979-46a0-85f1-222797349de4	f
1f8ae50c-d35f-438d-b919-a0021c67beea	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
a6df953f-60f9-46b6-83d9-0a81b62d04a5	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
a6df953f-60f9-46b6-83d9-0a81b62d04a5	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
a6df953f-60f9-46b6-83d9-0a81b62d04a5	2f4c6846-d426-4d40-a15f-1acd7351a946	t
a6df953f-60f9-46b6-83d9-0a81b62d04a5	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
a6df953f-60f9-46b6-83d9-0a81b62d04a5	1d2bd933-a550-4d11-aa78-258954290a9c	t
a6df953f-60f9-46b6-83d9-0a81b62d04a5	147f68f2-1deb-489e-90c1-1f0a216aca17	t
a6df953f-60f9-46b6-83d9-0a81b62d04a5	5b61aded-f5c8-4ad3-b779-065520195daa	f
a6df953f-60f9-46b6-83d9-0a81b62d04a5	d512f187-3acb-4f8a-a985-41a797d3e53f	f
a6df953f-60f9-46b6-83d9-0a81b62d04a5	3f34b32f-25ee-4770-979c-918b005c06c6	f
a6df953f-60f9-46b6-83d9-0a81b62d04a5	364cdea3-6979-46a0-85f1-222797349de4	f
a6df953f-60f9-46b6-83d9-0a81b62d04a5	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
f637d925-d634-4b92-ad79-fb1b387b3e2e	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
f637d925-d634-4b92-ad79-fb1b387b3e2e	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
f637d925-d634-4b92-ad79-fb1b387b3e2e	2f4c6846-d426-4d40-a15f-1acd7351a946	t
f637d925-d634-4b92-ad79-fb1b387b3e2e	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
f637d925-d634-4b92-ad79-fb1b387b3e2e	1d2bd933-a550-4d11-aa78-258954290a9c	t
f637d925-d634-4b92-ad79-fb1b387b3e2e	147f68f2-1deb-489e-90c1-1f0a216aca17	t
f637d925-d634-4b92-ad79-fb1b387b3e2e	5b61aded-f5c8-4ad3-b779-065520195daa	f
f637d925-d634-4b92-ad79-fb1b387b3e2e	d512f187-3acb-4f8a-a985-41a797d3e53f	f
f637d925-d634-4b92-ad79-fb1b387b3e2e	3f34b32f-25ee-4770-979c-918b005c06c6	f
f637d925-d634-4b92-ad79-fb1b387b3e2e	364cdea3-6979-46a0-85f1-222797349de4	f
f637d925-d634-4b92-ad79-fb1b387b3e2e	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
c1926955-f77b-4a15-8be9-fbab2b1f504f	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
c1926955-f77b-4a15-8be9-fbab2b1f504f	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
c1926955-f77b-4a15-8be9-fbab2b1f504f	2f4c6846-d426-4d40-a15f-1acd7351a946	t
c1926955-f77b-4a15-8be9-fbab2b1f504f	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
c1926955-f77b-4a15-8be9-fbab2b1f504f	1d2bd933-a550-4d11-aa78-258954290a9c	t
c1926955-f77b-4a15-8be9-fbab2b1f504f	147f68f2-1deb-489e-90c1-1f0a216aca17	t
c1926955-f77b-4a15-8be9-fbab2b1f504f	5b61aded-f5c8-4ad3-b779-065520195daa	f
c1926955-f77b-4a15-8be9-fbab2b1f504f	d512f187-3acb-4f8a-a985-41a797d3e53f	f
c1926955-f77b-4a15-8be9-fbab2b1f504f	3f34b32f-25ee-4770-979c-918b005c06c6	f
c1926955-f77b-4a15-8be9-fbab2b1f504f	364cdea3-6979-46a0-85f1-222797349de4	f
c1926955-f77b-4a15-8be9-fbab2b1f504f	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
60c887d6-2ce7-4fe9-98f0-fe2625266194	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
60c887d6-2ce7-4fe9-98f0-fe2625266194	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
60c887d6-2ce7-4fe9-98f0-fe2625266194	2f4c6846-d426-4d40-a15f-1acd7351a946	t
60c887d6-2ce7-4fe9-98f0-fe2625266194	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
60c887d6-2ce7-4fe9-98f0-fe2625266194	1d2bd933-a550-4d11-aa78-258954290a9c	t
60c887d6-2ce7-4fe9-98f0-fe2625266194	147f68f2-1deb-489e-90c1-1f0a216aca17	t
60c887d6-2ce7-4fe9-98f0-fe2625266194	5b61aded-f5c8-4ad3-b779-065520195daa	f
60c887d6-2ce7-4fe9-98f0-fe2625266194	d512f187-3acb-4f8a-a985-41a797d3e53f	f
60c887d6-2ce7-4fe9-98f0-fe2625266194	3f34b32f-25ee-4770-979c-918b005c06c6	f
60c887d6-2ce7-4fe9-98f0-fe2625266194	364cdea3-6979-46a0-85f1-222797349de4	f
60c887d6-2ce7-4fe9-98f0-fe2625266194	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
\.


--
-- Data for Name: client_scope_role_mapping; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.client_scope_role_mapping (scope_id, role_id) FROM stdin;
17958855-2814-4159-b3a1-5b40cdaeebe6	7a38715c-ec4b-4953-86f2-fa52ad0cea78
d512f187-3acb-4f8a-a985-41a797d3e53f	52834c63-0987-45b9-8394-1c0cb9e31f22
\.


--
-- Data for Name: component; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.component (id, name, parent_id, provider_id, provider_type, realm_id, sub_type) FROM stdin;
dbc76311-9714-4e51-998e-9ecb549ba8ea	Trusted Hosts	955a00d0-1411-4e86-8ef2-bdedffd7a66f	trusted-hosts	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	anonymous
882271df-9c3c-4b82-8b42-88d4d65eed76	Consent Required	955a00d0-1411-4e86-8ef2-bdedffd7a66f	consent-required	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	anonymous
c1eca008-1d81-4aeb-8096-b0183a7e13c4	Full Scope Disabled	955a00d0-1411-4e86-8ef2-bdedffd7a66f	scope	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	anonymous
588f0170-45c3-4808-b71e-71a46908cbc6	Max Clients Limit	955a00d0-1411-4e86-8ef2-bdedffd7a66f	max-clients	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	anonymous
f794d7a5-d8fd-434e-8e32-857ad5b5b632	Allowed Protocol Mapper Types	955a00d0-1411-4e86-8ef2-bdedffd7a66f	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	anonymous
03b11116-7b17-440c-8ba9-0f3038a8d9df	Allowed Client Scopes	955a00d0-1411-4e86-8ef2-bdedffd7a66f	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	anonymous
b28bdd30-ed56-4cbe-af56-0c0512300aba	Allowed Protocol Mapper Types	955a00d0-1411-4e86-8ef2-bdedffd7a66f	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	authenticated
9a364496-5735-4ced-b3df-86272cb9e8c6	Allowed Client Scopes	955a00d0-1411-4e86-8ef2-bdedffd7a66f	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	authenticated
121c26f0-1681-451c-9ef1-714fc0c2ec06	rsa-generated	955a00d0-1411-4e86-8ef2-bdedffd7a66f	rsa-generated	org.keycloak.keys.KeyProvider	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N
a18fe577-3902-47c3-a738-aa04164ac625	rsa-enc-generated	955a00d0-1411-4e86-8ef2-bdedffd7a66f	rsa-enc-generated	org.keycloak.keys.KeyProvider	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N
d43ee68e-8db8-4817-b33f-c783de9a292e	hmac-generated-hs512	955a00d0-1411-4e86-8ef2-bdedffd7a66f	hmac-generated	org.keycloak.keys.KeyProvider	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N
1bf142e8-97c1-4dbf-8cc6-9289144510cf	aes-generated	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aes-generated	org.keycloak.keys.KeyProvider	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N
87c17a1c-512c-4668-9c6b-3dc575cf9047	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	declarative-user-profile	org.keycloak.userprofile.UserProfileProvider	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N
208c6fa3-e822-4a44-b56f-718cdabd0187	Max Clients Limit	27d57df0-0794-4e96-92ac-85b802200864	max-clients	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	anonymous
e45d137f-cb9b-4533-b73d-a274ec4f44f6	Trusted Hosts	27d57df0-0794-4e96-92ac-85b802200864	trusted-hosts	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	anonymous
0619ceda-40a6-42b1-b7b5-dcb540a4b851	Allowed Protocol Mapper Types	27d57df0-0794-4e96-92ac-85b802200864	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	anonymous
5907d8ba-9a9c-4510-8335-838527a4003e	Full Scope Disabled	27d57df0-0794-4e96-92ac-85b802200864	scope	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	anonymous
57c0d14d-d909-466d-9d2b-9093313fd063	Allowed Client Scopes	27d57df0-0794-4e96-92ac-85b802200864	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	authenticated
a521fe4c-60da-4efd-82bc-aa8d5caaad3a	Allowed Protocol Mapper Types	27d57df0-0794-4e96-92ac-85b802200864	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	authenticated
719f531f-6d4d-435e-8a6c-5dfffd7557c5	Consent Required	27d57df0-0794-4e96-92ac-85b802200864	consent-required	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	anonymous
d064c128-5bb9-4f75-9e79-6fc52298f3f1	Allowed Client Scopes	27d57df0-0794-4e96-92ac-85b802200864	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	27d57df0-0794-4e96-92ac-85b802200864	anonymous
e0e2145b-3897-47ad-8aff-912fb7398e5f	hmac-generated-hs512	27d57df0-0794-4e96-92ac-85b802200864	hmac-generated	org.keycloak.keys.KeyProvider	27d57df0-0794-4e96-92ac-85b802200864	\N
2374452d-233e-4637-b16c-e5730c15c2ea	aes-generated	27d57df0-0794-4e96-92ac-85b802200864	aes-generated	org.keycloak.keys.KeyProvider	27d57df0-0794-4e96-92ac-85b802200864	\N
804c9af9-aa70-4761-93a7-543b75a82bac	rsa-enc-generated	27d57df0-0794-4e96-92ac-85b802200864	rsa-enc-generated	org.keycloak.keys.KeyProvider	27d57df0-0794-4e96-92ac-85b802200864	\N
25b1c4f7-f7c7-4261-b307-8875a358362f	rsa-generated	27d57df0-0794-4e96-92ac-85b802200864	rsa-generated	org.keycloak.keys.KeyProvider	27d57df0-0794-4e96-92ac-85b802200864	\N
\.


--
-- Data for Name: component_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.component_config (id, component_id, name, value) FROM stdin;
790d6602-3e62-402f-8651-389bca1da1b5	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
bd5d6c64-d636-4e5d-83f1-cec8c9283d33	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
7084f18e-a8bd-4f63-9d0b-207fef58d8d7	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	oidc-full-name-mapper
12b82a08-c47e-4bca-aaed-de8aa7320057	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	oidc-address-mapper
e67ecc46-e69d-49c7-a970-ac31db7d3250	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	saml-role-list-mapper
5f9cf7e1-741d-4675-9773-bd6f2c701a87	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
812031d9-d438-436f-9462-457d36a11109	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	saml-user-property-mapper
40b62db9-2129-4ea3-8bbd-5c212086aacd	f794d7a5-d8fd-434e-8e32-857ad5b5b632	allowed-protocol-mapper-types	saml-user-attribute-mapper
33159f73-cb7b-4cb8-9cc9-b95288f31edf	9a364496-5735-4ced-b3df-86272cb9e8c6	allow-default-scopes	true
454d03b0-78cc-4c4b-94c4-1af21a6d7319	588f0170-45c3-4808-b71e-71a46908cbc6	max-clients	200
a705c4f4-32a5-427e-956e-7273148da9d8	03b11116-7b17-440c-8ba9-0f3038a8d9df	allow-default-scopes	true
1706bbdc-d6fa-40ae-adaa-72b1698f2aba	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
b3664b4c-8f57-4274-92fb-c44870d4b7d0	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
23006c26-24b1-4f5d-85d8-8192f74b26a5	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	saml-user-property-mapper
7ea8bc49-4cd3-4c4f-850a-965d2833cd4b	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	oidc-full-name-mapper
c7a94c41-3716-4246-a62b-cc4456f66548	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	saml-role-list-mapper
cc376655-2e2a-4338-a80c-130d29a24e76	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
d6fff372-871b-4565-8948-8ceef7a8d9cb	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	saml-user-attribute-mapper
60aa96fb-a85f-46ef-8919-7a8c1fbb0729	b28bdd30-ed56-4cbe-af56-0c0512300aba	allowed-protocol-mapper-types	oidc-address-mapper
6b8eaadd-f18b-4d80-9fda-1bbe1bfac214	dbc76311-9714-4e51-998e-9ecb549ba8ea	client-uris-must-match	true
11040b5c-0fb2-4ded-a3ec-ac36178e8f78	dbc76311-9714-4e51-998e-9ecb549ba8ea	host-sending-registration-request-must-match	true
a1d724f4-2a80-4cbf-8cd7-85e821adee28	1bf142e8-97c1-4dbf-8cc6-9289144510cf	kid	6bee7da7-f90a-47ca-ba73-476ae7686634
c639fc63-a0e2-4718-9807-50b3c033506d	1bf142e8-97c1-4dbf-8cc6-9289144510cf	secret	GEkF0ZRH1_W5K-zR6qV9bA
e713cf71-85d7-425a-8b30-ed731a21715c	1bf142e8-97c1-4dbf-8cc6-9289144510cf	priority	100
2c1dd161-fa16-4b9c-a80a-04c69688da71	87c17a1c-512c-4668-9c6b-3dc575cf9047	kc.user.profile.config	{"attributes":[{"name":"username","displayName":"${username}","validations":{"length":{"min":3,"max":255},"username-prohibited-characters":{},"up-username-not-idn-homograph":{}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false},{"name":"email","displayName":"${email}","validations":{"email":{},"length":{"max":255}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false},{"name":"firstName","displayName":"${firstName}","validations":{"length":{"max":255},"person-name-prohibited-characters":{}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false},{"name":"lastName","displayName":"${lastName}","validations":{"length":{"max":255},"person-name-prohibited-characters":{}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false}],"groups":[{"name":"user-metadata","displayHeader":"User metadata","displayDescription":"Attributes, which refer to user metadata"}]}
573bc97b-a4f1-4f4b-8362-251b16a85a5f	a18fe577-3902-47c3-a738-aa04164ac625	privateKey	MIIEpQIBAAKCAQEAzqdbFo9Qe9ywE3t+bn4IcfTKYR/9nmHC1zEX0QKwL6IYPR8yB4cenrqln2zlPs5fB21r9wMuIHQCkrt+vRVB5ocMUOsDVSozzIeeCDjeAAEMUD0RbhkxzX6cpwjxv+DYYQ1cJL4+M4mD3KbDfA7i1v8b7tW4JkvNuHuFW7D8AuB8aYGLohBUBEQQQ6fgCtT0pNtal+Lri1qfKr1LrV4cXBDHIjBRCB6lRq22WHOw8tPSSn3k0Drk8u+TUdVgjTmEoBF9YesHTOxGa7XSfIh//1APNmjt2BO7fV6IwW/yV25VHsrMuU1GtlgLioL3d6HAtGUuNRiatrEh+l9xbrRTKwIDAQABAoIBAAFfCXL2Aa/YLxqmQdzYXR0MdrW3vih6jTAXKG/mJFWLg3i6OP9cuSpKd7MCP+ezyJfon6Ho1W0OGiTvgn7H5lQ+zQb8sdQ7tP03lBbNvpizJNBffLJSQr5Fut6kVsB0MQYJtJcEwkezzKCpMUlo++B7VlaUPJlPp5bvlyfPu9Tj+gr16fmDhuul+yu/8WTXg4650pYMaVkeITqgrcV/7pyv+DDWMI/WVjPCgg7RiDWtWPUOSGyi7sz+sEPlIvb69bVbYo/qE252AmyatXng+IbVposya+OCwFMaI7sgCdfCDoZhb4emZ81ROxN1m1drMJmIZ86KLteuWpwDtNBI/EECgYEA/cF5u8iokXR7HZW6awJpRoHtBQg2wobDVTeODFXsttMXkYRvcoDjPk+waKxQq2JBCw5hb7l8Qk+l8HfP2ZPmnEcl11oYvgoh0pcqOh9C61II7t4Dz+JOt6ees7Z/8MBuuAWKSsUHBdhj/QZUgVYgBhfPvonD6y0ijjssL6uWVSECgYEA0Hs8wNdN/p9ENR+2Y6fuLDWptLrEBg1qJfyUTkSBOa+kMkbV5+Rh9SJyt11+hreR0O00HVf1AgwtnlkZJ3Wey7836VFYdcN0GdTmDGvX9tPKkrf6l8eNxoBuOIgmQ0ACtFlxJYTu3JmviZ3MqRiZYh5n1DW3onhUhMYKElGykssCgYEAoQPQa8ByfgFsUaR9aoNYK74rmKLSpHKApaUfxGINVyDw9owTb5OrHhHQvUqB0Y4B+bMBTrRizWzevYw43jXEAev/bfukcYnaVldHGyRVAR7HvlIwFwvhqRV6VUx7OFfSqYASdUk6IJJjN915Z6wvm84mKyAdqi+0mo2fhwwY0yECgYEAvle1+S7aE93fjU0d3dDFoHGCNvLJ4+i9gF8iHG9pOHzHQevwgl6+nOvNpuJikabqJ8FZ8myK0krCH6+jSqaVy9oStx/AzwwbZTY+rxqLO9zUN65nycm1BIXfnBeaL44yqex7ZFEBMEHUxaVf5QcDi1TNYS+GMH0CVZLmQSF8E48CgYEAipGt99PgblU5jU66gptwFCPDOIyEkD+RfVwywDPAbsuWO58PI8jg35Qhe5zeTUN1bEAYqXmRHH3C1+3Ui3gevOWSP50FZUzYV1Sv92BnsterHqkrc3aNJpLjRPZYQmlBtgSOC/Tdi1czYJmKA8w6l6cPdOvdlh7ccOReJ/OmQX4=
91db6319-e07f-4d6b-8ab8-959a052115f5	a18fe577-3902-47c3-a738-aa04164ac625	certificate	MIICmzCCAYMCBgGbIipwXzANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjUxMjE1MTMxNzQ1WhcNMzUxMjE1MTMxOTI1WjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDOp1sWj1B73LATe35ufghx9MphH/2eYcLXMRfRArAvohg9HzIHhx6euqWfbOU+zl8HbWv3Ay4gdAKSu369FUHmhwxQ6wNVKjPMh54ION4AAQxQPRFuGTHNfpynCPG/4NhhDVwkvj4ziYPcpsN8DuLW/xvu1bgmS824e4VbsPwC4HxpgYuiEFQERBBDp+AK1PSk21qX4uuLWp8qvUutXhxcEMciMFEIHqVGrbZYc7Dy09JKfeTQOuTy75NR1WCNOYSgEX1h6wdM7EZrtdJ8iH//UA82aO3YE7t9XojBb/JXblUeysy5TUa2WAuKgvd3ocC0ZS41GJq2sSH6X3FutFMrAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAAhDoaobn6B8AR/18xSBVX2IKALNUtt5jhFqblZ1fc8NSeeavIFzShwiIggLLnOTmzn5Gj1ifv4ri9mTaV6Yem65COtCx4YxMC/LGTZdg/KZdD/CL0vdsSRqAFD1ysFnbG6QwX6AUjnl1zBib7wrNbEulZIJsDJlwy1syIaPN3HUhtevTix9Rh0ryQ6RQwqmYOhOLw++sYc7X/G6zZ0blU+aMh63jfvXPFrsMioBqlkeCmvWZu9GQLqUZV8SzsgJfMd1SWUMBXqLDQsJHdJmmxJc8LT90sPi+bq/5a6/1MP3FKdLGIB5zs67DZkxmLhMWdq43bbxKEVvztmf3p7gxb4=
2ece5956-9d2b-49cb-934e-3e358719e52c	a18fe577-3902-47c3-a738-aa04164ac625	algorithm	RSA-OAEP
1dad5390-e2e3-458e-90cc-8ca3dedbb150	a18fe577-3902-47c3-a738-aa04164ac625	priority	100
434d13a3-761b-4691-8e0b-6021a1a105ac	a18fe577-3902-47c3-a738-aa04164ac625	keyUse	ENC
33dac083-982d-4fa5-a4b6-7f6d68ba6e16	d43ee68e-8db8-4817-b33f-c783de9a292e	kid	e907291e-cd81-4c0c-9cc5-4d699ed9b333
c6a5ca98-bee1-46b2-a28d-c1dbed365507	d43ee68e-8db8-4817-b33f-c783de9a292e	algorithm	HS512
78097859-1ec2-4557-a0f9-71be339ce583	d43ee68e-8db8-4817-b33f-c783de9a292e	priority	100
11d9669f-9fa1-4ad5-93e3-693e6662039a	d43ee68e-8db8-4817-b33f-c783de9a292e	secret	bZj2yfSkziUBVvWyzQWwWxuy9l1t0AWLVKM2fPiEB7x1lfhOQzbMthTZ4kGQ-_MUtAo-lGUKmsR0YPKuJ66lujGhbQf9-KRYSXdkqNGgCfL1iTHGtNc1xTkp-o38VASd6oFvAdQ2C35sO12vrLhyzIUtvnJETPQRmCajM5dV7Gc
c8440360-99af-4d03-9766-19ba0c625ee5	121c26f0-1681-451c-9ef1-714fc0c2ec06	privateKey	MIIEpAIBAAKCAQEAvyQaQw9uFyySZGjQVzOWKFBqVNNF7nuMenfNqvE/RhJcOQVXTRdn92medeT/7jR0g+jDsq9QJPJDSXnqD/CM8Umhav2/RuSqhoqIS7AQRzGADaWzkRDuZNwcjizdoJyJ+A2HTTfnsTrMMuWlV4BVOiS0CxJKHekS9PUQfnGvAAEu/vGbKJYvOPh3YJMc6jtY/6JeiLMHvDPn8dP1LSebr3mGJxPu+nSFbK5G4Y2qFSrThAzTIgVyZysfjAWqt31M6I109WPXwyNySoYsp3NiGjRSNAilV1MpS1sCO1gXQUZHEs2/vSB4v8gm3o3cw9anxEPO6JHg6eYOQ+OLYfSwJQIDAQABAoIBAA9CYpZX9QIEnOtHMtrDU4mEYfjDpSGU23Irfk/XUqXVcWdb9cxBwhsOY4gl8AikR2kAfB8Xv94zOQv0n6sGGTpqFmjkORD/0F1NUfQ46hPE7+QnBl7eaynCKMVw74CS/rC+475WaDjN6N9nVfvWUveBVp5Lp38bzFeh+N8fVEk7q59lQwogDZl33ZIbrINSPt7QvCdBg1m+MKOfHy4TENQs1MRpTlxG5/9qiL58l1UAc4vg4znDBNeUjO13oFzAnIXJr+8cZIf63IdBbFH6nmfnnRMopjw3JJ545qfJkxMm36/XuUth67HbF34U/w5nCUAK/pj9gSdlQGKsxk91K0ECgYEA440kLfhGHBWaW7iSSoapWE7Y4pdVyENfYgwccMtv3Pd1VME7vBd2UK2mdyyNLBBS/bA4gKVTSL2mm6+VzsEVlUzbe4buJMCZzZk0cscRfvlmqt8VIyrUp6mBCX5ufiVrNkUzhSnjNDPE0ZYKlopONJJPlT/rGuUb4utNMAbXNjMCgYEA1wmjCDpWvh8vkvK081Gf/LlrAKP5Tcu9T8pT9HhPrSQq5i5azZ9od8Oal656VgOt7LXc+ki4fnoV6MDQQk4KGe/xG3KNykg+REulUZZz39+Hu/E+/Nja2EGt4TfQA71sippaXm92EkIXOv/gk5AiTUVRdC3uTTdc+BJEf41wuEcCgYBvfiVe/MnlUtRp4nqTV328Dg4IoBvg3tnqYYLB5Xvu6bSsjW1mUJyhFSR+Oe8Fyw3OzTwyFE9FUd9DYvnk7whTOfBEiy0+BryVV16yakVxUGP0jw99RqwhZlUaQL+EwXLRiYCf25E+b6sdAgY4EpYU/idOOp5IdD+ApMgSIxfprwKBgQDM7NMgSTBW+LNGr+M/qf70QeM19g3kVI/x1RgS9wC/OKNlPrGsGQjecVsGx/CvvcvmtB2Fqv2fEkuExxLwzRwVQbMc/BshtZ0ZSpmeWenNZGEe+zWSkjpkMps48Q5cMg2ZPKV4L3JuzesDf8uN9KKrzq5kME1T6rm/cvEyOSE9iwKBgQC5fMtqra+1SICaj/3hu1+0fYmGOHMDGSOIUTCGIkErBQoArorjlVYSthMIwn4OAgil36EuM2sLhVgrYZDw5itxfEJ3ggXJ8FcBJ5/nSSwLuxYUNzjS+693z5U/XiIDQIclxkLHmJpyXsBOak+gK4swA02R0EgAIW8IprjEqmIWQw==
81d45e9d-e3fc-42fb-a8f7-cf067c3d990e	121c26f0-1681-451c-9ef1-714fc0c2ec06	keyUse	SIG
0486df4b-09d7-4d9a-8f0e-ace46a382083	121c26f0-1681-451c-9ef1-714fc0c2ec06	certificate	MIICmzCCAYMCBgGbIipwEjANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjUxMjE1MTMxNzQ1WhcNMzUxMjE1MTMxOTI1WjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC/JBpDD24XLJJkaNBXM5YoUGpU00Xue4x6d82q8T9GElw5BVdNF2f3aZ515P/uNHSD6MOyr1Ak8kNJeeoP8IzxSaFq/b9G5KqGiohLsBBHMYANpbOREO5k3ByOLN2gnIn4DYdNN+exOswy5aVXgFU6JLQLEkod6RL09RB+ca8AAS7+8Zsoli84+HdgkxzqO1j/ol6Iswe8M+fx0/UtJ5uveYYnE+76dIVsrkbhjaoVKtOEDNMiBXJnKx+MBaq3fUzojXT1Y9fDI3JKhiync2IaNFI0CKVXUylLWwI7WBdBRkcSzb+9IHi/yCbejdzD1qfEQ87okeDp5g5D44th9LAlAgMBAAEwDQYJKoZIhvcNAQELBQADggEBALaaC471uJwHNgWygYram1DoU8FKUtP30J2yusngZ7t1gJqgZe0/uj5uCigon+bnh9ECVemjsmMubFajMHK9hpQtjrkVkY9FzyUnCzA/VrNGcInNHILtykluuhEE/Wl8VLJEbVtvlDcOgDcKQS1ASr+afaq/aBek9JW0EWWTkHtlTkQdLJknZS6zxHobqaZyQ/BMzvD2ncclHeO/PSuuiett4VBs4s8UVZa7hyKzLu8+lT3MYBW6ATHJGetPvI2RCGajt4BvjIOEnqcDhpqnYJel2Ktet0xQDI1MmpW4P85YUzYDeGaI56We6uBwa6YNzmUl3xZ1vp/7380GzybB1pw=
8a764632-c890-4bce-8edf-40de426f85c0	121c26f0-1681-451c-9ef1-714fc0c2ec06	priority	100
e4acad28-b407-40d6-8b94-7707a56a863c	208c6fa3-e822-4a44-b56f-718cdabd0187	max-clients	200
44acd5fb-6a70-4b10-86aa-94f26753f39d	e45d137f-cb9b-4533-b73d-a274ec4f44f6	client-uris-must-match	true
860a6dd4-7f68-48a6-9684-666bad943760	e45d137f-cb9b-4533-b73d-a274ec4f44f6	host-sending-registration-request-must-match	true
7212a4e1-2398-43b9-9b9e-e46cfff38be5	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
7dd40524-b7d3-4aef-803f-59a30a6025cc	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	oidc-full-name-mapper
21c7f4e8-d705-4700-88a2-9970cae6054d	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
a38177d7-ae57-4b46-b9b4-454dec753c9d	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	oidc-address-mapper
e82ebcf2-0507-45a5-8b60-1594803fc7dd	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	saml-role-list-mapper
4520e577-d9fb-465d-97cf-7de3f71fcee2	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
d7ad6abe-e7f3-4c50-b417-40d65111c59c	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	saml-user-attribute-mapper
f25801ec-7718-44fc-9b31-aef8bdaa9fde	0619ceda-40a6-42b1-b7b5-dcb540a4b851	allowed-protocol-mapper-types	saml-user-property-mapper
afbd9ea8-07c2-4b53-9bad-88b132414882	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
626d9d9e-9e39-4ff0-a529-075bca3631ad	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	saml-role-list-mapper
857b79f3-436b-4297-b529-fcbe017f055b	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	oidc-address-mapper
2d77e2e0-e037-40d6-862a-856a8a7df817	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	oidc-full-name-mapper
a577d2e9-9a5e-49b6-98e4-bda607c1c65c	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	saml-user-attribute-mapper
6fb1d7d0-020b-42ed-a56f-ae080b5f97ca	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
e2880cea-f04f-4779-882c-021bd7d540d2	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
a543f454-3958-461c-a1c6-8854a5814add	a521fe4c-60da-4efd-82bc-aa8d5caaad3a	allowed-protocol-mapper-types	saml-user-property-mapper
167a82ff-e53a-4e42-9a65-09f9ae33d8a9	57c0d14d-d909-466d-9d2b-9093313fd063	allow-default-scopes	true
636d315b-9bd9-493a-ba9d-52929c25b4d2	e0e2145b-3897-47ad-8aff-912fb7398e5f	kid	02bda723-e109-41de-a6cd-aac57bfc42c2
cd1a38fa-e7a8-49e5-9a8e-f65df60326e2	e0e2145b-3897-47ad-8aff-912fb7398e5f	priority	100
27d92c04-6661-43a1-bf3b-76fab90605a9	e0e2145b-3897-47ad-8aff-912fb7398e5f	algorithm	HS512
b9bdcfda-9aaa-4463-8cd0-e8ff7a7d4431	e0e2145b-3897-47ad-8aff-912fb7398e5f	secret	ba_CuX5IDuaXlk-vZ5jlctVV5Shsxc_L8ykdmcDy4eQcTUly4t3FGokm3xPVcpup36wkKCmAYIyZmraBp-6YBtQ0lsAwEvmVPlgkfApPXMaReH9SxX2hfMSwj0-EJgaEtU3OuS0_Gkwojjg938YMmLxbPb5fjqbjM1MAyg-75mQ
283c6348-764c-4ed8-9fad-1d77e5d6f899	2374452d-233e-4637-b16c-e5730c15c2ea	kid	f208dad8-d288-4beb-aa05-e1b0ee037a02
34261515-06d5-4d50-8141-2a67e5adb3a3	2374452d-233e-4637-b16c-e5730c15c2ea	secret	6AC2sLXwzIkVLdgTstKBpA
b1630a4c-17bf-4bf5-8712-84f411f753a7	2374452d-233e-4637-b16c-e5730c15c2ea	priority	100
8ce556d4-a177-423e-912a-5e148c75a71f	804c9af9-aa70-4761-93a7-543b75a82bac	priority	100
1b22ccee-7d79-4fa4-a32b-064651dbac45	804c9af9-aa70-4761-93a7-543b75a82bac	privateKey	MIIEpQIBAAKCAQEA909eyfE55ZnjTUrmJtqki9iv4uJFEnGq9Ib35+HoqKfjzrHQ6MKd+2dEajxL5TkiFgh4H/LzhtpjRTy76BnP8tKCO9jBOXZfqY8w7/bBIkH79rL16v/MwW71gpj0rlQ8ZdereUB09A7kmfIzdurSTtkGmW6wbPukDS3/wObl7lHlEBu5caeChFAJ1vSx2AzFkVFwMnBlksBLCY+jVGoO8LGaBjBGfsch41L9wddEV8wrCF301H0VOvJtX1j3BnuuQZ5AX/8baMj9/awkRrvrxSV/WfqFSl/EXhBd59MwsiHW48UavhV0dplVZ3x8L4Uxoso73s2ZuL7suNAdvfypFwIDAQABAoIBABHEcFaTxQlmGpAVVHRFev2CY3MqYbSnLpVYvlC4yIKYD+QWnvVJ822ksqPrPGH1zn7EvFSXRhWnH5X8J10lFZfStdaKMP+ULd/m+1NnZ+Kyg4vquYODkyNGec7tzDkGBjzO13E48e4Nb9umLI+w48u/CHFXeXIAS33tkxU5wW/IlZiwVec/QvaCkFiWQMjb0XyxW2EHI1qvZInx/hDkg61pB6xlZcWXXiS97fgSpNkPe/ISHcU7i9P1uNwE3H5yP7k7vbM/8nWGgIQyJdDjfN98u9y9CJLrnAF0wi0AgF4cCE3yXUIbLbSHLWjTSmrta6dQZEn1UmJK6OX/U1kkABECgYEA/kPaxXn1jUnmrKM9/h5TDboohrhnPWwQMtq7TGUirtnYyd0IrBxnoeBl+5Dm4ldbKrOQzcYoA49MgewoIWQJopAbz5Uuzq9eeC2tzIVDclAV/ZnJ5i7QjBAlAFcVh072cOyv1kg4y8sEkBJbUj7S2EsFeHACSTOWmSlA9wnnlQkCgYEA+P9d5qIIXHlq94Ap98ryViScl8odgd+/IAfC/pGehTFlbo79LxwLdLI3VQ2w4YmaZVwjYGYuAjzYUGC82ZZDGHZvxs8Jn4+f4I6e63tL5xJqXG0UVM1c7h6loGtZx2dQ9vm/Rsp6DpjLBN/wSeF7PSgQZdu0JtaJNNPkZ8LQ9R8CgYEAtmWsuX68pIc//9X2saXFRJKnYcVE4i30DNcWBz6Bu9awilaSUwzpVpln7yfKSNILpz07AjJFIBCa/JSRUSq3MrOYD7hf5IqvBR0XkSCD+qvyqoK47/PjTKaENJND8VW2udlAZkJW4/KWKlfQxNYmYFyo5vXK3gIw5VxPqyeixikCgYEAiOys73H1FR0zxEy3R2tT3ikd756WoV+wE2YRRbpAKNBkDesVsX1Dk3WZVe1EcpIf1FNZpN4ruNFKxtCbqS+nT+F5UCN0EEmDypHDNI1FzRjkYlUdlBCmZM93lwLRiQT4kgf+tmgLvNEq+1BGK+qRwayxb8HkjGL3apSHCsQn8lMCgYEAlzWUwFOmiPgq271wBeDOy+YN6JAUG9HK2s0V8KO+2iwKQ/gUHIhCMWoT4KP5bz8YCKTS1HBNJypUeQmi6uCSS+j7vvU9QnH1KUef3r+D36sTn80+WSvkuBl66MkvCqB9ubIHpST3qWhEWJIJSZSEKu6I24EZm0NUgYnzdCoXwh4=
475af2f5-9435-4fa8-817d-258aa9cb14ca	804c9af9-aa70-4761-93a7-543b75a82bac	certificate	MIICoTCCAYkCBgGbIipyvzANBgkqhkiG9w0BAQsFADAUMRIwEAYDVQQDDAlGSElSLUF1dGgwHhcNMjUxMjE1MTMxNzQ1WhcNMzUxMjE1MTMxOTI1WjAUMRIwEAYDVQQDDAlGSElSLUF1dGgwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD3T17J8TnlmeNNSuYm2qSL2K/i4kUScar0hvfn4eiop+POsdDowp37Z0RqPEvlOSIWCHgf8vOG2mNFPLvoGc/y0oI72ME5dl+pjzDv9sEiQfv2svXq/8zBbvWCmPSuVDxl16t5QHT0DuSZ8jN26tJO2QaZbrBs+6QNLf/A5uXuUeUQG7lxp4KEUAnW9LHYDMWRUXAycGWSwEsJj6NUag7wsZoGMEZ+xyHjUv3B10RXzCsIXfTUfRU68m1fWPcGe65BnkBf/xtoyP39rCRGu+vFJX9Z+oVKX8ReEF3n0zCyIdbjxRq+FXR2mVVnfHwvhTGiyjvezZm4vuy40B29/KkXAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAA63YzfS5gY83kEV8V4etEd4JND6Am4WETH9bBVYqwPL36w5PpUlt4EQKyMuQ3mimwgnDoRkLombd5wop+wELTy8MaVUWl2FBnmZag6fYKBibSygL/SqY85b2ziTym5y5dnRVFRS5xOyP6ywRfH3KVQCamcA5fIorjUedDlPz6Rys1yA3wh0YFncsESQ5ZbcDtkHoVSdq9opb+CIOrwKcVbnl0IDhOvDf+OO78zxu6fBYKfTzwzfbFvFy70F0a4Tt1AKXfjMebUgjil9oBshp9CDb3GtheoJKQS2Qb/7ZYazsXCYqK91Yn5VEZinzFhJntsaVh7jPnhf2inwhmsUdvc=
19977057-d548-4d7e-82db-e2c4eabfda38	804c9af9-aa70-4761-93a7-543b75a82bac	algorithm	RSA-OAEP
bc4bbc24-98e9-4979-830b-2839b0b8426d	25b1c4f7-f7c7-4261-b307-8875a358362f	priority	100
83c54842-c995-4668-b434-774cd75a2ed3	25b1c4f7-f7c7-4261-b307-8875a358362f	certificate	MIICoTCCAYkCBgGbIipzUTANBgkqhkiG9w0BAQsFADAUMRIwEAYDVQQDDAlGSElSLUF1dGgwHhcNMjUxMjE1MTMxNzQ2WhcNMzUxMjE1MTMxOTI2WjAUMRIwEAYDVQQDDAlGSElSLUF1dGgwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCDi/mzbDuJ0KlGp9Nv2eRjXsPNhFHXFWZg/sy+Q8kwEkvlvcsS1OvCBn4iNeCvOQMYClcN0nLgszCkoP1nEqp99xwKKPQCniodQ9bUZxBw6fo00+3p1VyIo/adrcBV+/JKhVqTF0Q6rgVYqM2X5QqzZ/kEy9yZqfmfpGcyTNKhyXVi8bosMIjSwRwIcmLGPxavtlpyHsGMtfD1pl7Qe46PzJje6KHJB2bx6jaVGpzUjYCENmeiy9Ya4HookkxCBgW5m8u2TS2JB5peJ21YtbYYChgeZcZ1DZglQ9LJpwfVE1wvwQyUkC0TH6pINKvR/yCA4REltKenTm4nkKhdLB9/AgMBAAEwDQYJKoZIhvcNAQELBQADggEBADFtbf89CHXExDNH/KTTlxARlf1maUUKq6ji6Pkmg3pOaWF0xXzAPmjSzWWPhy5qESD97x06I3362VcwkgW5z7G8wbZonYR9NRowURxoRF0oAKSgdGaBJ7XqnXLJCdUdygmhR6cB55pd7iCtB+Xdqvsj3l1cn7rOqHXVFBqyHL2w8dq/AlFQP0ZKQxRqsLexw68rzTw16jFRGn3mY/Lw78yiSL/1Dc7+lsR3UziGkICQS8FhX73Iib2Scxi3udZ65f+ByLZVTZV50DnmHnuMWkIASqBQQkPNgYKTjFZnlAApMWjBOWNgmQvt2HG2ziQtDseH3MIFb2l/DYS1NXqrPQs=
25ea8319-36e1-49ff-b046-b2c3176a1262	25b1c4f7-f7c7-4261-b307-8875a358362f	privateKey	MIIEowIBAAKCAQEAg4v5s2w7idCpRqfTb9nkY17DzYRR1xVmYP7MvkPJMBJL5b3LEtTrwgZ+IjXgrzkDGApXDdJy4LMwpKD9ZxKqffccCij0Ap4qHUPW1GcQcOn6NNPt6dVciKP2na3AVfvySoVakxdEOq4FWKjNl+UKs2f5BMvcman5n6RnMkzSocl1YvG6LDCI0sEcCHJixj8Wr7Zach7BjLXw9aZe0HuOj8yY3uihyQdm8eo2lRqc1I2AhDZnosvWGuB6KJJMQgYFuZvLtk0tiQeaXidtWLW2GAoYHmXGdQ2YJUPSyacH1RNcL8EMlJAtEx+qSDSr0f8ggOERJbSnp05uJ5CoXSwffwIDAQABAoIBAA6m0w+QcQs3EfucKrktEDqfLfjgkYr+x7Hq/1v7yddQWmLC4nD9BStNtNPTo2xw0a7mS+7urzvmyXa0tbS6yAGSue1JxW/bNP6gdTegKR0iemtS5Y9jY9SWSpwiY6dQEhsJwl5au487nb3Tw151NN1pqbtGh5IX9AU7dwELvHQnhsmv+DVGg6IYC5iZMMT2WJn1duzSXHixgf4wxlG7O+ownszNC4yJgWmtAiNzM8vLGczpiz++MnBdnvEDQbvvQ5xP7tjXPPU+HTYjccHNkjwRleu2HdoDxEDgGpqNmBoaBOckBI/Lp5jkRItnaKm/EYkDD2W5d4YRDnqQo8tPHeECgYEAuO19ljlu3Eghn0nrHQhcZ5ma3UYzQ9msZpzrpTvxX5LH4H3+eOnMMEfgumkvlE9l7S//+/BlaBqyHgtTGCjOg27pF/khPp3VfcOoiCnaXCRf9+aHlXhN9Kb7dszBbOWPWL3Is//amRc3Dc9CGuzijamGLPacKwNGeIF9MDnbGl8CgYEAthp8/96HxnAD9W+J6Eo8Mz2GViUooHhhxbJ3Z+9an045TzQm8VoVLk+cCQkHNEDyAF0pPvQx7BQQbv7H5rU2VR4oD69ru/qbXHDy4NxS0a3PRCxLERXxYJcwIEYwKRavhMxwMZau5pwDEw8EfCCnZFEeK1U0dvnCUyA9yYoPTuECgYBm59lL4DfdotH65tJLvJxXFjYETg03A4kZLNdAgoPF0FMjjFkwBcIXV9gpQ2EzoZ8xhtVm6BY2ASz+5QRfXE3W+8AAFCU4x/HGYzuEUe3t+lvhAkqOlXyj2Mv0BurX40KKekmWSJjnOfDr4VqCyzEi7aP5n1213cO4SS5VyMww9wKBgQCPiqObYQKvdZ55ObmAA/wd+9JHVzUGAL45AqtCnxZU2mksOJS1zGdDwPbi3F30X3kitkyL1hr/1vT5ORXDknXIdGPpsUH/w9Pw8wtQGfuiUho9x5hIWH6Sv7nsxsaxrLMfv7J0NC2bk8CMplrHqUmpNpPMXnZjjg4STijGE3BroQKBgCTAURdQkraFsuI7LI2W015AysabwKLk0ixrNpnjVjJ4aw7TmlnO1oFg3hHzabi0NhiKSt2lt+nxBS143x4BDpU001nqtSSgaToPkxTch4IdabPGx1GGzXfU2tZiEgtGyQ2Hy61iuFdf/3CQi8LtiPq2qpjj6jIXYE7p+/ccowt1
42dd4135-5ced-4f3b-a44d-5579125b0945	d064c128-5bb9-4f75-9e79-6fc52298f3f1	allow-default-scopes	true
\.


--
-- Data for Name: composite_role; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.composite_role (composite, child_role) FROM stdin;
417a29f4-aa8b-4560-9f73-eafc6a417349	abee5d94-e14e-4da8-a52b-fc8bfee803e1
417a29f4-aa8b-4560-9f73-eafc6a417349	b8d87e42-d5fa-4f0d-9f71-8bb47a6f19e4
417a29f4-aa8b-4560-9f73-eafc6a417349	bc60158b-e3c0-4741-93aa-c57ed824bf24
417a29f4-aa8b-4560-9f73-eafc6a417349	fe17e097-a79b-4b77-926d-7b610a73779e
417a29f4-aa8b-4560-9f73-eafc6a417349	bc81c759-7eda-486e-8fa6-f0285ec5526d
417a29f4-aa8b-4560-9f73-eafc6a417349	97576643-c60d-4ec3-8ce0-22e15900a8af
417a29f4-aa8b-4560-9f73-eafc6a417349	b0f23d7f-184c-42ff-80a9-a870088b76ec
417a29f4-aa8b-4560-9f73-eafc6a417349	77aad39e-f806-4ef8-bd46-9aa2ca9274ef
417a29f4-aa8b-4560-9f73-eafc6a417349	6d9cd6b3-aad4-4162-a1c4-f143daa199cf
417a29f4-aa8b-4560-9f73-eafc6a417349	f2b96aa3-b8b2-4503-bbde-550296c1cb3d
417a29f4-aa8b-4560-9f73-eafc6a417349	770148f1-42ee-4101-8665-4c08fe83adcd
417a29f4-aa8b-4560-9f73-eafc6a417349	983f5ad0-b1b9-431f-a471-a636ac43e15f
417a29f4-aa8b-4560-9f73-eafc6a417349	9ed69905-e59e-4908-ad1b-0944270a1d74
417a29f4-aa8b-4560-9f73-eafc6a417349	ffe4c690-8b6e-45f0-b78c-8214815b3402
417a29f4-aa8b-4560-9f73-eafc6a417349	c464e592-eed4-43ac-87c5-87fba272e40a
417a29f4-aa8b-4560-9f73-eafc6a417349	a6083528-1902-4af9-b3f6-72525c4bb7b1
417a29f4-aa8b-4560-9f73-eafc6a417349	234b1742-3ab8-44b2-ba89-8a14f7a7dece
417a29f4-aa8b-4560-9f73-eafc6a417349	7184fb13-9253-47a6-a0c4-f81c9f45b808
74bbf2b8-0473-4e83-a487-af069f08b188	dfa15bab-46e0-4d19-8321-7f1014329997
bc81c759-7eda-486e-8fa6-f0285ec5526d	a6083528-1902-4af9-b3f6-72525c4bb7b1
fe17e097-a79b-4b77-926d-7b610a73779e	7184fb13-9253-47a6-a0c4-f81c9f45b808
fe17e097-a79b-4b77-926d-7b610a73779e	c464e592-eed4-43ac-87c5-87fba272e40a
74bbf2b8-0473-4e83-a487-af069f08b188	60f5bc18-fe0d-43bd-adcf-cdc636e356f2
60f5bc18-fe0d-43bd-adcf-cdc636e356f2	1021a5c2-2e5f-4c81-93fd-0282b86c6297
122cb6c9-b10f-40eb-b3c0-34d1308f4a0e	eb8e5a6a-849b-4d16-86e9-4979836e4676
417a29f4-aa8b-4560-9f73-eafc6a417349	c32377a3-fca7-474f-82dd-4b9341a45d8e
74bbf2b8-0473-4e83-a487-af069f08b188	7a38715c-ec4b-4953-86f2-fa52ad0cea78
74bbf2b8-0473-4e83-a487-af069f08b188	126087ae-3a7d-4f40-8437-9b63d998a259
417a29f4-aa8b-4560-9f73-eafc6a417349	a3155255-4da9-456a-b035-d9df8f93820d
417a29f4-aa8b-4560-9f73-eafc6a417349	bf2799d2-4514-466f-9b2f-fe047aaecacd
417a29f4-aa8b-4560-9f73-eafc6a417349	81786bf9-dee9-42e1-b8be-911a2547d2d8
417a29f4-aa8b-4560-9f73-eafc6a417349	7c2887a1-b59f-4e40-8e82-9b500a226705
417a29f4-aa8b-4560-9f73-eafc6a417349	3204aa25-9901-46fb-902a-e85f4d58bbe3
417a29f4-aa8b-4560-9f73-eafc6a417349	0b8d3d20-6f20-486a-adff-ead7e8df1718
417a29f4-aa8b-4560-9f73-eafc6a417349	ae2492d8-5ca8-404e-8e4f-46748b6e9d0f
417a29f4-aa8b-4560-9f73-eafc6a417349	79814634-1fb7-4738-bb0c-f3a26ce8405b
417a29f4-aa8b-4560-9f73-eafc6a417349	5e8eea9f-553c-4b02-870c-408103d739e7
417a29f4-aa8b-4560-9f73-eafc6a417349	be091733-a521-4e90-8a3e-d59520ec109e
417a29f4-aa8b-4560-9f73-eafc6a417349	46b7408d-3faa-45af-8d1b-01af85e25b2c
417a29f4-aa8b-4560-9f73-eafc6a417349	89c2f2e3-f8ce-4e01-aa56-d4d89566c479
417a29f4-aa8b-4560-9f73-eafc6a417349	01db9827-1af9-4a62-8dfa-b5f8a5e0aa5a
417a29f4-aa8b-4560-9f73-eafc6a417349	19bd2559-cac7-4f52-a726-e8881068c85b
417a29f4-aa8b-4560-9f73-eafc6a417349	3648783f-d2a9-4016-befd-880f5ee43e9e
417a29f4-aa8b-4560-9f73-eafc6a417349	71d02f81-09a2-4706-9bce-4c01a0199e2b
417a29f4-aa8b-4560-9f73-eafc6a417349	2f154e09-1aa6-4d54-9110-938d903abf88
7c2887a1-b59f-4e40-8e82-9b500a226705	3648783f-d2a9-4016-befd-880f5ee43e9e
81786bf9-dee9-42e1-b8be-911a2547d2d8	19bd2559-cac7-4f52-a726-e8881068c85b
81786bf9-dee9-42e1-b8be-911a2547d2d8	2f154e09-1aa6-4d54-9110-938d903abf88
22b8abad-460c-464d-afae-3b6a2380d7d0	85f1cc16-c9c7-44e3-a710-698ec79178b8
39c3feae-b3f5-49b1-a6cf-1f91960d022d	52834c63-0987-45b9-8394-1c0cb9e31f22
39c3feae-b3f5-49b1-a6cf-1f91960d022d	12d01785-a93c-419d-8161-71201cfc13a2
39c3feae-b3f5-49b1-a6cf-1f91960d022d	8c4fb8e5-3b13-40fa-9de3-84f178372a1b
39c3feae-b3f5-49b1-a6cf-1f91960d022d	22b8abad-460c-464d-afae-3b6a2380d7d0
567adb13-3c8d-4bf7-9ae1-34a5699882d9	6758f8e6-bafe-4e07-a73c-dd46d5de4aa8
567adb13-3c8d-4bf7-9ae1-34a5699882d9	d9388adb-1d17-4c6e-a982-191c08c6f844
567adb13-3c8d-4bf7-9ae1-34a5699882d9	bccf785d-7c5d-4f0b-a119-5cb0ea5758a8
567adb13-3c8d-4bf7-9ae1-34a5699882d9	9cbfe1f6-ffae-474f-a00b-3752475a19fc
567adb13-3c8d-4bf7-9ae1-34a5699882d9	a1bf2364-7a57-41e2-a69a-74209fcf6579
567adb13-3c8d-4bf7-9ae1-34a5699882d9	3c1ee422-a51f-4001-a95b-a70a6449052e
567adb13-3c8d-4bf7-9ae1-34a5699882d9	9a27d858-0e46-4baf-9657-d5e38d56c4fe
567adb13-3c8d-4bf7-9ae1-34a5699882d9	be5bf3f8-5751-4915-a9a5-aef3a75b2b5e
567adb13-3c8d-4bf7-9ae1-34a5699882d9	c08c5ffe-b64d-432c-b7ee-5fcb4086bb35
567adb13-3c8d-4bf7-9ae1-34a5699882d9	4627e2ab-c964-4065-9fc4-9e1dd183c262
567adb13-3c8d-4bf7-9ae1-34a5699882d9	3bf13298-a242-453e-af63-b610281d5627
567adb13-3c8d-4bf7-9ae1-34a5699882d9	cb351478-8b13-47c5-be79-6ac3af3dd6d0
567adb13-3c8d-4bf7-9ae1-34a5699882d9	57a7ddb3-80d7-4da5-8629-22f931f13916
567adb13-3c8d-4bf7-9ae1-34a5699882d9	33975d52-f850-4929-acfe-7543a9dc4312
567adb13-3c8d-4bf7-9ae1-34a5699882d9	2eccc0fe-1c76-4338-a188-e22f1c7271e5
567adb13-3c8d-4bf7-9ae1-34a5699882d9	74da0329-b34a-43e1-b14b-0791997e6af2
567adb13-3c8d-4bf7-9ae1-34a5699882d9	cb2eea3d-fe96-4004-bbd2-5784a158867c
567adb13-3c8d-4bf7-9ae1-34a5699882d9	ebc6b236-f812-41a3-a572-1dbfdcd50a1e
c08c5ffe-b64d-432c-b7ee-5fcb4086bb35	57a7ddb3-80d7-4da5-8629-22f931f13916
d9388adb-1d17-4c6e-a982-191c08c6f844	cb351478-8b13-47c5-be79-6ac3af3dd6d0
d9388adb-1d17-4c6e-a982-191c08c6f844	a1bf2364-7a57-41e2-a69a-74209fcf6579
df77a96a-da8d-4ec3-8598-9ca5ce6c5fd9	020c24b4-383a-4463-9c50-8107c2b257e1
417a29f4-aa8b-4560-9f73-eafc6a417349	99bee062-a066-43aa-bcd6-f49a57501d37
\.


--
-- Data for Name: credential; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.credential (id, salt, type, user_id, created_date, user_label, secret_data, credential_data, priority, version) FROM stdin;
2e98701a-2c74-4841-b950-5ca4dba43341	\N	password	b9db48fc-0c61-4a58-adc4-60a3f190fd93	1765804766512	\N	{"value":"ruaQOM3SSe+QvJxUa5cc/W6+tsSTMcU47VFdk4hTGPQ=","salt":"ofVhtMj2MbL+7r+Rl2Kgcg==","additionalParameters":{}}	{"hashIterations":5,"algorithm":"argon2","additionalParameters":{"hashLength":["32"],"memory":["7168"],"type":["id"],"version":["1.3"],"parallelism":["1"]}}	10	0
804dfc38-7c11-4b41-999a-fae62237f14d	\N	password	5441cea9-fcf2-419e-bc20-948c3c283c98	1765807601141	My password	{"value":"b5INtbt5Qgjhh7T8SR0ZfQH6nFOThiP3viwmgdoDXXg=","salt":"ycdDyeK96VcqkSaxC5CZzw==","additionalParameters":{}}	{"hashIterations":5,"algorithm":"argon2","additionalParameters":{"hashLength":["32"],"memory":["7168"],"type":["id"],"version":["1.3"],"parallelism":["1"]}}	10	1
340a186b-45e7-40d1-b2df-743c99b3cefa	\N	password	97503f80-1f4f-4ae6-8b58-eb50a082acf9	1765807665110	My password	{"value":"kmhlKGtMogI2lmurV+BPfPynplJAaIxl7G+2EZMc2y4=","salt":"32rXXfpG8X2Ik3Vl1JGQeg==","additionalParameters":{}}	{"hashIterations":5,"algorithm":"argon2","additionalParameters":{"hashLength":["32"],"memory":["7168"],"type":["id"],"version":["1.3"],"parallelism":["1"]}}	10	1
ed0338e1-6eee-460b-a840-a69a26b7d586	\N	password	df11bc00-e0e6-4924-941d-3627fdd16992	1765807695369	My password	{"value":"FWdq7VOR7X/nSPIh99xcVvjuSz9dXWtf52QVGuZHDLs=","salt":"t/ja+V16ylYIj3h9sEH/2w==","additionalParameters":{}}	{"hashIterations":5,"algorithm":"argon2","additionalParameters":{"hashLength":["32"],"memory":["7168"],"type":["id"],"version":["1.3"],"parallelism":["1"]}}	10	1
5426ce34-2676-4c67-a300-bb0e072c4cd0	\N	password	499edbce-5fcd-4a08-9ac0-113864a2afa3	1765892167157	My password	{"value":"l/DmP5l34AD+2HCs0ZPpQVbqUwzU8jq/s6A3G82SWIo=","salt":"pgU1jXnCvYjeN3htVxkACg==","additionalParameters":{}}	{"hashIterations":5,"algorithm":"argon2","additionalParameters":{"hashLength":["32"],"memory":["7168"],"type":["id"],"version":["1.3"],"parallelism":["1"]}}	10	1
\.


--
-- Data for Name: databasechangelog; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.databasechangelog (id, author, filename, dateexecuted, orderexecuted, exectype, md5sum, description, comments, tag, liquibase, contexts, labels, deployment_id) FROM stdin;
1.0.0.Final-KEYCLOAK-5461	sthorger@redhat.com	META-INF/jpa-changelog-1.0.0.Final.xml	2025-12-15 13:19:18.324225	1	EXECUTED	9:6f1016664e21e16d26517a4418f5e3df	createTable tableName=APPLICATION_DEFAULT_ROLES; createTable tableName=CLIENT; createTable tableName=CLIENT_SESSION; createTable tableName=CLIENT_SESSION_ROLE; createTable tableName=COMPOSITE_ROLE; createTable tableName=CREDENTIAL; createTable tab...		\N	4.33.0	\N	\N	5804754638
1.0.0.Final-KEYCLOAK-5461	sthorger@redhat.com	META-INF/db2-jpa-changelog-1.0.0.Final.xml	2025-12-15 13:19:18.333567	2	MARK_RAN	9:828775b1596a07d1200ba1d49e5e3941	createTable tableName=APPLICATION_DEFAULT_ROLES; createTable tableName=CLIENT; createTable tableName=CLIENT_SESSION; createTable tableName=CLIENT_SESSION_ROLE; createTable tableName=COMPOSITE_ROLE; createTable tableName=CREDENTIAL; createTable tab...		\N	4.33.0	\N	\N	5804754638
1.1.0.Beta1	sthorger@redhat.com	META-INF/jpa-changelog-1.1.0.Beta1.xml	2025-12-15 13:19:18.378899	3	EXECUTED	9:5f090e44a7d595883c1fb61f4b41fd38	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION; createTable tableName=CLIENT_ATTRIBUTES; createTable tableName=CLIENT_SESSION_NOTE; createTable tableName=APP_NODE_REGISTRATIONS; addColumn table...		\N	4.33.0	\N	\N	5804754638
1.1.0.Final	sthorger@redhat.com	META-INF/jpa-changelog-1.1.0.Final.xml	2025-12-15 13:19:18.385371	4	EXECUTED	9:c07e577387a3d2c04d1adc9aaad8730e	renameColumn newColumnName=EVENT_TIME, oldColumnName=TIME, tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	5804754638
1.2.0.Beta1	psilva@redhat.com	META-INF/jpa-changelog-1.2.0.Beta1.xml	2025-12-15 13:19:18.509979	5	EXECUTED	9:b68ce996c655922dbcd2fe6b6ae72686	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION; createTable tableName=PROTOCOL_MAPPER; createTable tableName=PROTOCOL_MAPPER_CONFIG; createTable tableName=...		\N	4.33.0	\N	\N	5804754638
1.2.0.Beta1	psilva@redhat.com	META-INF/db2-jpa-changelog-1.2.0.Beta1.xml	2025-12-15 13:19:18.515037	6	MARK_RAN	9:543b5c9989f024fe35c6f6c5a97de88e	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION; createTable tableName=PROTOCOL_MAPPER; createTable tableName=PROTOCOL_MAPPER_CONFIG; createTable tableName=...		\N	4.33.0	\N	\N	5804754638
1.2.0.RC1	bburke@redhat.com	META-INF/jpa-changelog-1.2.0.CR1.xml	2025-12-15 13:19:18.629145	7	EXECUTED	9:765afebbe21cf5bbca048e632df38336	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete tableName=USER_SESSION; createTable tableName=MIGRATION_MODEL; createTable tableName=IDENTITY_P...		\N	4.33.0	\N	\N	5804754638
1.2.0.RC1	bburke@redhat.com	META-INF/db2-jpa-changelog-1.2.0.CR1.xml	2025-12-15 13:19:18.63448	8	MARK_RAN	9:db4a145ba11a6fdaefb397f6dbf829a1	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete tableName=USER_SESSION; createTable tableName=MIGRATION_MODEL; createTable tableName=IDENTITY_P...		\N	4.33.0	\N	\N	5804754638
1.2.0.Final	keycloak	META-INF/jpa-changelog-1.2.0.Final.xml	2025-12-15 13:19:18.640764	9	EXECUTED	9:9d05c7be10cdb873f8bcb41bc3a8ab23	update tableName=CLIENT; update tableName=CLIENT; update tableName=CLIENT		\N	4.33.0	\N	\N	5804754638
1.3.0	bburke@redhat.com	META-INF/jpa-changelog-1.3.0.xml	2025-12-15 13:19:18.777513	10	EXECUTED	9:18593702353128d53111f9b1ff0b82b8	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete tableName=USER_SESSION; createTable tableName=ADMI...		\N	4.33.0	\N	\N	5804754638
1.4.0	bburke@redhat.com	META-INF/jpa-changelog-1.4.0.xml	2025-12-15 13:19:18.836004	11	EXECUTED	9:6122efe5f090e41a85c0f1c9e52cbb62	delete tableName=CLIENT_SESSION_AUTH_STATUS; delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete table...		\N	4.33.0	\N	\N	5804754638
1.4.0	bburke@redhat.com	META-INF/db2-jpa-changelog-1.4.0.xml	2025-12-15 13:19:18.839699	12	MARK_RAN	9:e1ff28bf7568451453f844c5d54bb0b5	delete tableName=CLIENT_SESSION_AUTH_STATUS; delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete table...		\N	4.33.0	\N	\N	5804754638
1.5.0	bburke@redhat.com	META-INF/jpa-changelog-1.5.0.xml	2025-12-15 13:19:18.856674	13	EXECUTED	9:7af32cd8957fbc069f796b61217483fd	delete tableName=CLIENT_SESSION_AUTH_STATUS; delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete table...		\N	4.33.0	\N	\N	5804754638
1.6.1_from15	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2025-12-15 13:19:18.907078	14	EXECUTED	9:6005e15e84714cd83226bf7879f54190	addColumn tableName=REALM; addColumn tableName=KEYCLOAK_ROLE; addColumn tableName=CLIENT; createTable tableName=OFFLINE_USER_SESSION; createTable tableName=OFFLINE_CLIENT_SESSION; addPrimaryKey constraintName=CONSTRAINT_OFFL_US_SES_PK2, tableName=...		\N	4.33.0	\N	\N	5804754638
1.6.1_from16-pre	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2025-12-15 13:19:18.910041	15	MARK_RAN	9:bf656f5a2b055d07f314431cae76f06c	delete tableName=OFFLINE_CLIENT_SESSION; delete tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
1.6.1_from16	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2025-12-15 13:19:18.913713	16	MARK_RAN	9:f8dadc9284440469dcf71e25ca6ab99b	dropPrimaryKey constraintName=CONSTRAINT_OFFLINE_US_SES_PK, tableName=OFFLINE_USER_SESSION; dropPrimaryKey constraintName=CONSTRAINT_OFFLINE_CL_SES_PK, tableName=OFFLINE_CLIENT_SESSION; addColumn tableName=OFFLINE_USER_SESSION; update tableName=OF...		\N	4.33.0	\N	\N	5804754638
1.6.1	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2025-12-15 13:19:18.917452	17	EXECUTED	9:d41d8cd98f00b204e9800998ecf8427e	empty		\N	4.33.0	\N	\N	5804754638
1.7.0	bburke@redhat.com	META-INF/jpa-changelog-1.7.0.xml	2025-12-15 13:19:18.967737	18	EXECUTED	9:3368ff0be4c2855ee2dd9ca813b38d8e	createTable tableName=KEYCLOAK_GROUP; createTable tableName=GROUP_ROLE_MAPPING; createTable tableName=GROUP_ATTRIBUTE; createTable tableName=USER_GROUP_MEMBERSHIP; createTable tableName=REALM_DEFAULT_GROUPS; addColumn tableName=IDENTITY_PROVIDER; ...		\N	4.33.0	\N	\N	5804754638
1.8.0	mposolda@redhat.com	META-INF/jpa-changelog-1.8.0.xml	2025-12-15 13:19:19.020692	19	EXECUTED	9:8ac2fb5dd030b24c0570a763ed75ed20	addColumn tableName=IDENTITY_PROVIDER; createTable tableName=CLIENT_TEMPLATE; createTable tableName=CLIENT_TEMPLATE_ATTRIBUTES; createTable tableName=TEMPLATE_SCOPE_MAPPING; dropNotNullConstraint columnName=CLIENT_ID, tableName=PROTOCOL_MAPPER; ad...		\N	4.33.0	\N	\N	5804754638
1.8.0-2	keycloak	META-INF/jpa-changelog-1.8.0.xml	2025-12-15 13:19:19.027067	20	EXECUTED	9:f91ddca9b19743db60e3057679810e6c	dropDefaultValue columnName=ALGORITHM, tableName=CREDENTIAL; update tableName=CREDENTIAL		\N	4.33.0	\N	\N	5804754638
22.0.5-24031	keycloak	META-INF/jpa-changelog-22.0.0.xml	2025-12-15 13:19:22.262467	119	MARK_RAN	9:a60d2d7b315ec2d3eba9e2f145f9df28	customChange		\N	4.33.0	\N	\N	5804754638
1.8.0	mposolda@redhat.com	META-INF/db2-jpa-changelog-1.8.0.xml	2025-12-15 13:19:19.030366	21	MARK_RAN	9:831e82914316dc8a57dc09d755f23c51	addColumn tableName=IDENTITY_PROVIDER; createTable tableName=CLIENT_TEMPLATE; createTable tableName=CLIENT_TEMPLATE_ATTRIBUTES; createTable tableName=TEMPLATE_SCOPE_MAPPING; dropNotNullConstraint columnName=CLIENT_ID, tableName=PROTOCOL_MAPPER; ad...		\N	4.33.0	\N	\N	5804754638
1.8.0-2	keycloak	META-INF/db2-jpa-changelog-1.8.0.xml	2025-12-15 13:19:19.033787	22	MARK_RAN	9:f91ddca9b19743db60e3057679810e6c	dropDefaultValue columnName=ALGORITHM, tableName=CREDENTIAL; update tableName=CREDENTIAL		\N	4.33.0	\N	\N	5804754638
1.9.0	mposolda@redhat.com	META-INF/jpa-changelog-1.9.0.xml	2025-12-15 13:19:19.090714	23	EXECUTED	9:bc3d0f9e823a69dc21e23e94c7a94bb1	update tableName=REALM; update tableName=REALM; update tableName=REALM; update tableName=REALM; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=REALM; update tableName=REALM; customChange; dr...		\N	4.33.0	\N	\N	5804754638
1.9.1	keycloak	META-INF/jpa-changelog-1.9.1.xml	2025-12-15 13:19:19.09809	24	EXECUTED	9:c9999da42f543575ab790e76439a2679	modifyDataType columnName=PRIVATE_KEY, tableName=REALM; modifyDataType columnName=PUBLIC_KEY, tableName=REALM; modifyDataType columnName=CERTIFICATE, tableName=REALM		\N	4.33.0	\N	\N	5804754638
1.9.1	keycloak	META-INF/db2-jpa-changelog-1.9.1.xml	2025-12-15 13:19:19.100994	25	MARK_RAN	9:0d6c65c6f58732d81569e77b10ba301d	modifyDataType columnName=PRIVATE_KEY, tableName=REALM; modifyDataType columnName=CERTIFICATE, tableName=REALM		\N	4.33.0	\N	\N	5804754638
1.9.2	keycloak	META-INF/jpa-changelog-1.9.2.xml	2025-12-15 13:19:19.330669	26	EXECUTED	9:fc576660fc016ae53d2d4778d84d86d0	createIndex indexName=IDX_USER_EMAIL, tableName=USER_ENTITY; createIndex indexName=IDX_USER_ROLE_MAPPING, tableName=USER_ROLE_MAPPING; createIndex indexName=IDX_USER_GROUP_MAPPING, tableName=USER_GROUP_MEMBERSHIP; createIndex indexName=IDX_USER_CO...		\N	4.33.0	\N	\N	5804754638
authz-2.0.0	psilva@redhat.com	META-INF/jpa-changelog-authz-2.0.0.xml	2025-12-15 13:19:19.430922	27	EXECUTED	9:43ed6b0da89ff77206289e87eaa9c024	createTable tableName=RESOURCE_SERVER; addPrimaryKey constraintName=CONSTRAINT_FARS, tableName=RESOURCE_SERVER; addUniqueConstraint constraintName=UK_AU8TT6T700S9V50BU18WS5HA6, tableName=RESOURCE_SERVER; createTable tableName=RESOURCE_SERVER_RESOU...		\N	4.33.0	\N	\N	5804754638
authz-2.5.1	psilva@redhat.com	META-INF/jpa-changelog-authz-2.5.1.xml	2025-12-15 13:19:19.436589	28	EXECUTED	9:44bae577f551b3738740281eceb4ea70	update tableName=RESOURCE_SERVER_POLICY		\N	4.33.0	\N	\N	5804754638
2.1.0-KEYCLOAK-5461	bburke@redhat.com	META-INF/jpa-changelog-2.1.0.xml	2025-12-15 13:19:19.531661	29	EXECUTED	9:bd88e1f833df0420b01e114533aee5e8	createTable tableName=BROKER_LINK; createTable tableName=FED_USER_ATTRIBUTE; createTable tableName=FED_USER_CONSENT; createTable tableName=FED_USER_CONSENT_ROLE; createTable tableName=FED_USER_CONSENT_PROT_MAPPER; createTable tableName=FED_USER_CR...		\N	4.33.0	\N	\N	5804754638
2.2.0	bburke@redhat.com	META-INF/jpa-changelog-2.2.0.xml	2025-12-15 13:19:19.549098	30	EXECUTED	9:a7022af5267f019d020edfe316ef4371	addColumn tableName=ADMIN_EVENT_ENTITY; createTable tableName=CREDENTIAL_ATTRIBUTE; createTable tableName=FED_CREDENTIAL_ATTRIBUTE; modifyDataType columnName=VALUE, tableName=CREDENTIAL; addForeignKeyConstraint baseTableName=FED_CREDENTIAL_ATTRIBU...		\N	4.33.0	\N	\N	5804754638
2.3.0	bburke@redhat.com	META-INF/jpa-changelog-2.3.0.xml	2025-12-15 13:19:19.573376	31	EXECUTED	9:fc155c394040654d6a79227e56f5e25a	createTable tableName=FEDERATED_USER; addPrimaryKey constraintName=CONSTR_FEDERATED_USER, tableName=FEDERATED_USER; dropDefaultValue columnName=TOTP, tableName=USER_ENTITY; dropColumn columnName=TOTP, tableName=USER_ENTITY; addColumn tableName=IDE...		\N	4.33.0	\N	\N	5804754638
2.4.0	bburke@redhat.com	META-INF/jpa-changelog-2.4.0.xml	2025-12-15 13:19:19.57782	32	EXECUTED	9:eac4ffb2a14795e5dc7b426063e54d88	customChange		\N	4.33.0	\N	\N	5804754638
2.5.0	bburke@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2025-12-15 13:19:19.583957	33	EXECUTED	9:54937c05672568c4c64fc9524c1e9462	customChange; modifyDataType columnName=USER_ID, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
2.5.0-unicode-oracle	hmlnarik@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2025-12-15 13:19:19.58666	34	MARK_RAN	9:f9753208029f582525ed12011a19d054	modifyDataType columnName=DESCRIPTION, tableName=AUTHENTICATION_FLOW; modifyDataType columnName=DESCRIPTION, tableName=CLIENT_TEMPLATE; modifyDataType columnName=DESCRIPTION, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=DESCRIPTION,...		\N	4.33.0	\N	\N	5804754638
2.5.0-unicode-other-dbs	hmlnarik@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2025-12-15 13:19:19.617747	35	EXECUTED	9:33d72168746f81f98ae3a1e8e0ca3554	modifyDataType columnName=DESCRIPTION, tableName=AUTHENTICATION_FLOW; modifyDataType columnName=DESCRIPTION, tableName=CLIENT_TEMPLATE; modifyDataType columnName=DESCRIPTION, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=DESCRIPTION,...		\N	4.33.0	\N	\N	5804754638
2.5.0-duplicate-email-support	slawomir@dabek.name	META-INF/jpa-changelog-2.5.0.xml	2025-12-15 13:19:19.624445	36	EXECUTED	9:61b6d3d7a4c0e0024b0c839da283da0c	addColumn tableName=REALM		\N	4.33.0	\N	\N	5804754638
2.5.0-unique-group-names	hmlnarik@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2025-12-15 13:19:19.633972	37	EXECUTED	9:8dcac7bdf7378e7d823cdfddebf72fda	addUniqueConstraint constraintName=SIBLING_NAMES, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	5804754638
2.5.1	bburke@redhat.com	META-INF/jpa-changelog-2.5.1.xml	2025-12-15 13:19:19.639336	38	EXECUTED	9:a2b870802540cb3faa72098db5388af3	addColumn tableName=FED_USER_CONSENT		\N	4.33.0	\N	\N	5804754638
3.0.0	bburke@redhat.com	META-INF/jpa-changelog-3.0.0.xml	2025-12-15 13:19:19.644571	39	EXECUTED	9:132a67499ba24bcc54fb5cbdcfe7e4c0	addColumn tableName=IDENTITY_PROVIDER		\N	4.33.0	\N	\N	5804754638
3.2.0-fix	keycloak	META-INF/jpa-changelog-3.2.0.xml	2025-12-15 13:19:19.647084	40	MARK_RAN	9:938f894c032f5430f2b0fafb1a243462	addNotNullConstraint columnName=REALM_ID, tableName=CLIENT_INITIAL_ACCESS		\N	4.33.0	\N	\N	5804754638
3.2.0-fix-with-keycloak-5416	keycloak	META-INF/jpa-changelog-3.2.0.xml	2025-12-15 13:19:19.650143	41	MARK_RAN	9:845c332ff1874dc5d35974b0babf3006	dropIndex indexName=IDX_CLIENT_INIT_ACC_REALM, tableName=CLIENT_INITIAL_ACCESS; addNotNullConstraint columnName=REALM_ID, tableName=CLIENT_INITIAL_ACCESS; createIndex indexName=IDX_CLIENT_INIT_ACC_REALM, tableName=CLIENT_INITIAL_ACCESS		\N	4.33.0	\N	\N	5804754638
3.2.0-fix-offline-sessions	hmlnarik	META-INF/jpa-changelog-3.2.0.xml	2025-12-15 13:19:19.655584	42	EXECUTED	9:fc86359c079781adc577c5a217e4d04c	customChange		\N	4.33.0	\N	\N	5804754638
3.2.0-fixed	keycloak	META-INF/jpa-changelog-3.2.0.xml	2025-12-15 13:19:20.67394	43	EXECUTED	9:59a64800e3c0d09b825f8a3b444fa8f4	addColumn tableName=REALM; dropPrimaryKey constraintName=CONSTRAINT_OFFL_CL_SES_PK2, tableName=OFFLINE_CLIENT_SESSION; dropColumn columnName=CLIENT_SESSION_ID, tableName=OFFLINE_CLIENT_SESSION; addPrimaryKey constraintName=CONSTRAINT_OFFL_CL_SES_P...		\N	4.33.0	\N	\N	5804754638
3.3.0	keycloak	META-INF/jpa-changelog-3.3.0.xml	2025-12-15 13:19:20.67985	44	EXECUTED	9:d48d6da5c6ccf667807f633fe489ce88	addColumn tableName=USER_ENTITY		\N	4.33.0	\N	\N	5804754638
authz-3.4.0.CR1-resource-server-pk-change-part1	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2025-12-15 13:19:20.685626	45	EXECUTED	9:dde36f7973e80d71fceee683bc5d2951	addColumn tableName=RESOURCE_SERVER_POLICY; addColumn tableName=RESOURCE_SERVER_RESOURCE; addColumn tableName=RESOURCE_SERVER_SCOPE		\N	4.33.0	\N	\N	5804754638
authz-3.4.0.CR1-resource-server-pk-change-part2-KEYCLOAK-6095	hmlnarik@redhat.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2025-12-15 13:19:20.68991	46	EXECUTED	9:b855e9b0a406b34fa323235a0cf4f640	customChange		\N	4.33.0	\N	\N	5804754638
authz-3.4.0.CR1-resource-server-pk-change-part3-fixed	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2025-12-15 13:19:20.69232	47	MARK_RAN	9:51abbacd7b416c50c4421a8cabf7927e	dropIndex indexName=IDX_RES_SERV_POL_RES_SERV, tableName=RESOURCE_SERVER_POLICY; dropIndex indexName=IDX_RES_SRV_RES_RES_SRV, tableName=RESOURCE_SERVER_RESOURCE; dropIndex indexName=IDX_RES_SRV_SCOPE_RES_SRV, tableName=RESOURCE_SERVER_SCOPE		\N	4.33.0	\N	\N	5804754638
authz-3.4.0.CR1-resource-server-pk-change-part3-fixed-nodropindex	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2025-12-15 13:19:20.783509	48	EXECUTED	9:bdc99e567b3398bac83263d375aad143	addNotNullConstraint columnName=RESOURCE_SERVER_CLIENT_ID, tableName=RESOURCE_SERVER_POLICY; addNotNullConstraint columnName=RESOURCE_SERVER_CLIENT_ID, tableName=RESOURCE_SERVER_RESOURCE; addNotNullConstraint columnName=RESOURCE_SERVER_CLIENT_ID, ...		\N	4.33.0	\N	\N	5804754638
authn-3.4.0.CR1-refresh-token-max-reuse	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2025-12-15 13:19:20.789489	49	EXECUTED	9:d198654156881c46bfba39abd7769e69	addColumn tableName=REALM		\N	4.33.0	\N	\N	5804754638
3.4.0	keycloak	META-INF/jpa-changelog-3.4.0.xml	2025-12-15 13:19:20.857376	50	EXECUTED	9:cfdd8736332ccdd72c5256ccb42335db	addPrimaryKey constraintName=CONSTRAINT_REALM_DEFAULT_ROLES, tableName=REALM_DEFAULT_ROLES; addPrimaryKey constraintName=CONSTRAINT_COMPOSITE_ROLE, tableName=COMPOSITE_ROLE; addPrimaryKey constraintName=CONSTR_REALM_DEFAULT_GROUPS, tableName=REALM...		\N	4.33.0	\N	\N	5804754638
3.4.0-KEYCLOAK-5230	hmlnarik@redhat.com	META-INF/jpa-changelog-3.4.0.xml	2025-12-15 13:19:21.066528	51	EXECUTED	9:7c84de3d9bd84d7f077607c1a4dcb714	createIndex indexName=IDX_FU_ATTRIBUTE, tableName=FED_USER_ATTRIBUTE; createIndex indexName=IDX_FU_CONSENT, tableName=FED_USER_CONSENT; createIndex indexName=IDX_FU_CONSENT_RU, tableName=FED_USER_CONSENT; createIndex indexName=IDX_FU_CREDENTIAL, t...		\N	4.33.0	\N	\N	5804754638
3.4.1	psilva@redhat.com	META-INF/jpa-changelog-3.4.1.xml	2025-12-15 13:19:21.072695	52	EXECUTED	9:5a6bb36cbefb6a9d6928452c0852af2d	modifyDataType columnName=VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
3.4.2	keycloak	META-INF/jpa-changelog-3.4.2.xml	2025-12-15 13:19:21.076625	53	EXECUTED	9:8f23e334dbc59f82e0a328373ca6ced0	update tableName=REALM		\N	4.33.0	\N	\N	5804754638
3.4.2-KEYCLOAK-5172	mkanis@redhat.com	META-INF/jpa-changelog-3.4.2.xml	2025-12-15 13:19:21.080615	54	EXECUTED	9:9156214268f09d970cdf0e1564d866af	update tableName=CLIENT		\N	4.33.0	\N	\N	5804754638
4.0.0-KEYCLOAK-6335	bburke@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2025-12-15 13:19:21.091788	55	EXECUTED	9:db806613b1ed154826c02610b7dbdf74	createTable tableName=CLIENT_AUTH_FLOW_BINDINGS; addPrimaryKey constraintName=C_CLI_FLOW_BIND, tableName=CLIENT_AUTH_FLOW_BINDINGS		\N	4.33.0	\N	\N	5804754638
4.0.0-CLEANUP-UNUSED-TABLE	bburke@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2025-12-15 13:19:21.099136	56	EXECUTED	9:229a041fb72d5beac76bb94a5fa709de	dropTable tableName=CLIENT_IDENTITY_PROV_MAPPING		\N	4.33.0	\N	\N	5804754638
4.0.0-KEYCLOAK-6228	bburke@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2025-12-15 13:19:21.139714	57	EXECUTED	9:079899dade9c1e683f26b2aa9ca6ff04	dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; dropNotNullConstraint columnName=CLIENT_ID, tableName=USER_CONSENT; addColumn tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHO...		\N	4.33.0	\N	\N	5804754638
4.0.0-KEYCLOAK-5579-fixed	mposolda@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2025-12-15 13:19:21.396913	58	EXECUTED	9:139b79bcbbfe903bb1c2d2a4dbf001d9	dropForeignKeyConstraint baseTableName=CLIENT_TEMPLATE_ATTRIBUTES, constraintName=FK_CL_TEMPL_ATTR_TEMPL; renameTable newTableName=CLIENT_SCOPE_ATTRIBUTES, oldTableName=CLIENT_TEMPLATE_ATTRIBUTES; renameColumn newColumnName=SCOPE_ID, oldColumnName...		\N	4.33.0	\N	\N	5804754638
authz-4.0.0.CR1	psilva@redhat.com	META-INF/jpa-changelog-authz-4.0.0.CR1.xml	2025-12-15 13:19:21.426255	59	EXECUTED	9:b55738ad889860c625ba2bf483495a04	createTable tableName=RESOURCE_SERVER_PERM_TICKET; addPrimaryKey constraintName=CONSTRAINT_FAPMT, tableName=RESOURCE_SERVER_PERM_TICKET; addForeignKeyConstraint baseTableName=RESOURCE_SERVER_PERM_TICKET, constraintName=FK_FRSRHO213XCX4WNKOG82SSPMT...		\N	4.33.0	\N	\N	5804754638
authz-4.0.0.Beta3	psilva@redhat.com	META-INF/jpa-changelog-authz-4.0.0.Beta3.xml	2025-12-15 13:19:21.432733	60	EXECUTED	9:e0057eac39aa8fc8e09ac6cfa4ae15fe	addColumn tableName=RESOURCE_SERVER_POLICY; addColumn tableName=RESOURCE_SERVER_PERM_TICKET; addForeignKeyConstraint baseTableName=RESOURCE_SERVER_PERM_TICKET, constraintName=FK_FRSRPO2128CX4WNKOG82SSRFY, referencedTableName=RESOURCE_SERVER_POLICY		\N	4.33.0	\N	\N	5804754638
authz-4.2.0.Final	mhajas@redhat.com	META-INF/jpa-changelog-authz-4.2.0.Final.xml	2025-12-15 13:19:21.440779	61	EXECUTED	9:42a33806f3a0443fe0e7feeec821326c	createTable tableName=RESOURCE_URIS; addForeignKeyConstraint baseTableName=RESOURCE_URIS, constraintName=FK_RESOURCE_SERVER_URIS, referencedTableName=RESOURCE_SERVER_RESOURCE; customChange; dropColumn columnName=URI, tableName=RESOURCE_SERVER_RESO...		\N	4.33.0	\N	\N	5804754638
authz-4.2.0.Final-KEYCLOAK-9944	hmlnarik@redhat.com	META-INF/jpa-changelog-authz-4.2.0.Final.xml	2025-12-15 13:19:21.456379	62	EXECUTED	9:9968206fca46eecc1f51db9c024bfe56	addPrimaryKey constraintName=CONSTRAINT_RESOUR_URIS_PK, tableName=RESOURCE_URIS		\N	4.33.0	\N	\N	5804754638
4.2.0-KEYCLOAK-6313	wadahiro@gmail.com	META-INF/jpa-changelog-4.2.0.xml	2025-12-15 13:19:21.461668	63	EXECUTED	9:92143a6daea0a3f3b8f598c97ce55c3d	addColumn tableName=REQUIRED_ACTION_PROVIDER		\N	4.33.0	\N	\N	5804754638
4.3.0-KEYCLOAK-7984	wadahiro@gmail.com	META-INF/jpa-changelog-4.3.0.xml	2025-12-15 13:19:21.46493	64	EXECUTED	9:82bab26a27195d889fb0429003b18f40	update tableName=REQUIRED_ACTION_PROVIDER		\N	4.33.0	\N	\N	5804754638
4.6.0-KEYCLOAK-7950	psilva@redhat.com	META-INF/jpa-changelog-4.6.0.xml	2025-12-15 13:19:21.468053	65	EXECUTED	9:e590c88ddc0b38b0ae4249bbfcb5abc3	update tableName=RESOURCE_SERVER_RESOURCE		\N	4.33.0	\N	\N	5804754638
4.6.0-KEYCLOAK-8377	keycloak	META-INF/jpa-changelog-4.6.0.xml	2025-12-15 13:19:21.504443	66	EXECUTED	9:5c1f475536118dbdc38d5d7977950cc0	createTable tableName=ROLE_ATTRIBUTE; addPrimaryKey constraintName=CONSTRAINT_ROLE_ATTRIBUTE_PK, tableName=ROLE_ATTRIBUTE; addForeignKeyConstraint baseTableName=ROLE_ATTRIBUTE, constraintName=FK_ROLE_ATTRIBUTE_ID, referencedTableName=KEYCLOAK_ROLE...		\N	4.33.0	\N	\N	5804754638
4.6.0-KEYCLOAK-8555	gideonray@gmail.com	META-INF/jpa-changelog-4.6.0.xml	2025-12-15 13:19:21.528387	67	EXECUTED	9:e7c9f5f9c4d67ccbbcc215440c718a17	createIndex indexName=IDX_COMPONENT_PROVIDER_TYPE, tableName=COMPONENT		\N	4.33.0	\N	\N	5804754638
4.7.0-KEYCLOAK-1267	sguilhen@redhat.com	META-INF/jpa-changelog-4.7.0.xml	2025-12-15 13:19:21.534303	68	EXECUTED	9:88e0bfdda924690d6f4e430c53447dd5	addColumn tableName=REALM		\N	4.33.0	\N	\N	5804754638
4.7.0-KEYCLOAK-7275	keycloak	META-INF/jpa-changelog-4.7.0.xml	2025-12-15 13:19:21.562414	69	EXECUTED	9:f53177f137e1c46b6a88c59ec1cb5218	renameColumn newColumnName=CREATED_ON, oldColumnName=LAST_SESSION_REFRESH, tableName=OFFLINE_USER_SESSION; addNotNullConstraint columnName=CREATED_ON, tableName=OFFLINE_USER_SESSION; addColumn tableName=OFFLINE_USER_SESSION; customChange; createIn...		\N	4.33.0	\N	\N	5804754638
4.8.0-KEYCLOAK-8835	sguilhen@redhat.com	META-INF/jpa-changelog-4.8.0.xml	2025-12-15 13:19:21.5686	70	EXECUTED	9:a74d33da4dc42a37ec27121580d1459f	addNotNullConstraint columnName=SSO_MAX_LIFESPAN_REMEMBER_ME, tableName=REALM; addNotNullConstraint columnName=SSO_IDLE_TIMEOUT_REMEMBER_ME, tableName=REALM		\N	4.33.0	\N	\N	5804754638
authz-7.0.0-KEYCLOAK-10443	psilva@redhat.com	META-INF/jpa-changelog-authz-7.0.0.xml	2025-12-15 13:19:21.574194	71	EXECUTED	9:fd4ade7b90c3b67fae0bfcfcb42dfb5f	addColumn tableName=RESOURCE_SERVER		\N	4.33.0	\N	\N	5804754638
8.0.0-adding-credential-columns	keycloak	META-INF/jpa-changelog-8.0.0.xml	2025-12-15 13:19:21.581034	72	EXECUTED	9:aa072ad090bbba210d8f18781b8cebf4	addColumn tableName=CREDENTIAL; addColumn tableName=FED_USER_CREDENTIAL		\N	4.33.0	\N	\N	5804754638
8.0.0-updating-credential-data-not-oracle-fixed	keycloak	META-INF/jpa-changelog-8.0.0.xml	2025-12-15 13:19:21.586517	73	EXECUTED	9:1ae6be29bab7c2aa376f6983b932be37	update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL		\N	4.33.0	\N	\N	5804754638
8.0.0-updating-credential-data-oracle-fixed	keycloak	META-INF/jpa-changelog-8.0.0.xml	2025-12-15 13:19:21.589314	74	MARK_RAN	9:14706f286953fc9a25286dbd8fb30d97	update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL		\N	4.33.0	\N	\N	5804754638
8.0.0-credential-cleanup-fixed	keycloak	META-INF/jpa-changelog-8.0.0.xml	2025-12-15 13:19:21.605063	75	EXECUTED	9:2b9cc12779be32c5b40e2e67711a218b	dropDefaultValue columnName=COUNTER, tableName=CREDENTIAL; dropDefaultValue columnName=DIGITS, tableName=CREDENTIAL; dropDefaultValue columnName=PERIOD, tableName=CREDENTIAL; dropDefaultValue columnName=ALGORITHM, tableName=CREDENTIAL; dropColumn ...		\N	4.33.0	\N	\N	5804754638
8.0.0-resource-tag-support	keycloak	META-INF/jpa-changelog-8.0.0.xml	2025-12-15 13:19:21.63423	76	EXECUTED	9:91fa186ce7a5af127a2d7a91ee083cc5	addColumn tableName=MIGRATION_MODEL; createIndex indexName=IDX_UPDATE_TIME, tableName=MIGRATION_MODEL		\N	4.33.0	\N	\N	5804754638
9.0.0-always-display-client	keycloak	META-INF/jpa-changelog-9.0.0.xml	2025-12-15 13:19:21.640531	77	EXECUTED	9:6335e5c94e83a2639ccd68dd24e2e5ad	addColumn tableName=CLIENT		\N	4.33.0	\N	\N	5804754638
9.0.0-drop-constraints-for-column-increase	keycloak	META-INF/jpa-changelog-9.0.0.xml	2025-12-15 13:19:21.644038	78	MARK_RAN	9:6bdb5658951e028bfe16fa0a8228b530	dropUniqueConstraint constraintName=UK_FRSR6T700S9V50BU18WS5PMT, tableName=RESOURCE_SERVER_PERM_TICKET; dropUniqueConstraint constraintName=UK_FRSR6T700S9V50BU18WS5HA6, tableName=RESOURCE_SERVER_RESOURCE; dropPrimaryKey constraintName=CONSTRAINT_O...		\N	4.33.0	\N	\N	5804754638
9.0.0-increase-column-size-federated-fk	keycloak	META-INF/jpa-changelog-9.0.0.xml	2025-12-15 13:19:21.667194	79	EXECUTED	9:d5bc15a64117ccad481ce8792d4c608f	modifyDataType columnName=CLIENT_ID, tableName=FED_USER_CONSENT; modifyDataType columnName=CLIENT_REALM_CONSTRAINT, tableName=KEYCLOAK_ROLE; modifyDataType columnName=OWNER, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=CLIENT_ID, ta...		\N	4.33.0	\N	\N	5804754638
9.0.0-recreate-constraints-after-column-increase	keycloak	META-INF/jpa-changelog-9.0.0.xml	2025-12-15 13:19:21.670136	80	MARK_RAN	9:077cba51999515f4d3e7ad5619ab592c	addNotNullConstraint columnName=CLIENT_ID, tableName=OFFLINE_CLIENT_SESSION; addNotNullConstraint columnName=OWNER, tableName=RESOURCE_SERVER_PERM_TICKET; addNotNullConstraint columnName=REQUESTER, tableName=RESOURCE_SERVER_PERM_TICKET; addNotNull...		\N	4.33.0	\N	\N	5804754638
9.0.1-add-index-to-client.client_id	keycloak	META-INF/jpa-changelog-9.0.1.xml	2025-12-15 13:19:21.70853	81	EXECUTED	9:be969f08a163bf47c6b9e9ead8ac2afb	createIndex indexName=IDX_CLIENT_ID, tableName=CLIENT		\N	4.33.0	\N	\N	5804754638
9.0.1-KEYCLOAK-12579-drop-constraints	keycloak	META-INF/jpa-changelog-9.0.1.xml	2025-12-15 13:19:21.711152	82	MARK_RAN	9:6d3bb4408ba5a72f39bd8a0b301ec6e3	dropUniqueConstraint constraintName=SIBLING_NAMES, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	5804754638
9.0.1-KEYCLOAK-12579-add-not-null-constraint	keycloak	META-INF/jpa-changelog-9.0.1.xml	2025-12-15 13:19:21.718484	83	EXECUTED	9:966bda61e46bebf3cc39518fbed52fa7	addNotNullConstraint columnName=PARENT_GROUP, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	5804754638
9.0.1-KEYCLOAK-12579-recreate-constraints	keycloak	META-INF/jpa-changelog-9.0.1.xml	2025-12-15 13:19:21.721186	84	MARK_RAN	9:8dcac7bdf7378e7d823cdfddebf72fda	addUniqueConstraint constraintName=SIBLING_NAMES, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	5804754638
9.0.1-add-index-to-events	keycloak	META-INF/jpa-changelog-9.0.1.xml	2025-12-15 13:19:21.752404	85	EXECUTED	9:7d93d602352a30c0c317e6a609b56599	createIndex indexName=IDX_EVENT_TIME, tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	5804754638
map-remove-ri	keycloak	META-INF/jpa-changelog-11.0.0.xml	2025-12-15 13:19:21.760761	86	EXECUTED	9:71c5969e6cdd8d7b6f47cebc86d37627	dropForeignKeyConstraint baseTableName=REALM, constraintName=FK_TRAF444KK6QRKMS7N56AIWQ5Y; dropForeignKeyConstraint baseTableName=KEYCLOAK_ROLE, constraintName=FK_KJHO5LE2C0RAL09FL8CM9WFW9		\N	4.33.0	\N	\N	5804754638
map-remove-ri	keycloak	META-INF/jpa-changelog-12.0.0.xml	2025-12-15 13:19:21.774513	87	EXECUTED	9:a9ba7d47f065f041b7da856a81762021	dropForeignKeyConstraint baseTableName=REALM_DEFAULT_GROUPS, constraintName=FK_DEF_GROUPS_GROUP; dropForeignKeyConstraint baseTableName=REALM_DEFAULT_ROLES, constraintName=FK_H4WPD7W4HSOOLNI3H0SW7BTJE; dropForeignKeyConstraint baseTableName=CLIENT...		\N	4.33.0	\N	\N	5804754638
12.1.0-add-realm-localization-table	keycloak	META-INF/jpa-changelog-12.0.0.xml	2025-12-15 13:19:21.789579	88	EXECUTED	9:fffabce2bc01e1a8f5110d5278500065	createTable tableName=REALM_LOCALIZATIONS; addPrimaryKey tableName=REALM_LOCALIZATIONS		\N	4.33.0	\N	\N	5804754638
default-roles	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.796246	89	EXECUTED	9:fa8a5b5445e3857f4b010bafb5009957	addColumn tableName=REALM; customChange		\N	4.33.0	\N	\N	5804754638
default-roles-cleanup	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.804442	90	EXECUTED	9:67ac3241df9a8582d591c5ed87125f39	dropTable tableName=REALM_DEFAULT_ROLES; dropTable tableName=CLIENT_DEFAULT_ROLES		\N	4.33.0	\N	\N	5804754638
13.0.0-KEYCLOAK-16844	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.832481	91	EXECUTED	9:ad1194d66c937e3ffc82386c050ba089	createIndex indexName=IDX_OFFLINE_USS_PRELOAD, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
map-remove-ri-13.0.0	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.842068	92	EXECUTED	9:d9be619d94af5a2f5d07b9f003543b91	dropForeignKeyConstraint baseTableName=DEFAULT_CLIENT_SCOPE, constraintName=FK_R_DEF_CLI_SCOPE_SCOPE; dropForeignKeyConstraint baseTableName=CLIENT_SCOPE_CLIENT, constraintName=FK_C_CLI_SCOPE_SCOPE; dropForeignKeyConstraint baseTableName=CLIENT_SC...		\N	4.33.0	\N	\N	5804754638
13.0.0-KEYCLOAK-17992-drop-constraints	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.844876	93	MARK_RAN	9:544d201116a0fcc5a5da0925fbbc3bde	dropPrimaryKey constraintName=C_CLI_SCOPE_BIND, tableName=CLIENT_SCOPE_CLIENT; dropIndex indexName=IDX_CLSCOPE_CL, tableName=CLIENT_SCOPE_CLIENT; dropIndex indexName=IDX_CL_CLSCOPE, tableName=CLIENT_SCOPE_CLIENT		\N	4.33.0	\N	\N	5804754638
13.0.0-increase-column-size-federated	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.858454	94	EXECUTED	9:43c0c1055b6761b4b3e89de76d612ccf	modifyDataType columnName=CLIENT_ID, tableName=CLIENT_SCOPE_CLIENT; modifyDataType columnName=SCOPE_ID, tableName=CLIENT_SCOPE_CLIENT		\N	4.33.0	\N	\N	5804754638
13.0.0-KEYCLOAK-17992-recreate-constraints	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.861469	95	MARK_RAN	9:8bd711fd0330f4fe980494ca43ab1139	addNotNullConstraint columnName=CLIENT_ID, tableName=CLIENT_SCOPE_CLIENT; addNotNullConstraint columnName=SCOPE_ID, tableName=CLIENT_SCOPE_CLIENT; addPrimaryKey constraintName=C_CLI_SCOPE_BIND, tableName=CLIENT_SCOPE_CLIENT; createIndex indexName=...		\N	4.33.0	\N	\N	5804754638
json-string-accomodation-fixed	keycloak	META-INF/jpa-changelog-13.0.0.xml	2025-12-15 13:19:21.869002	96	EXECUTED	9:e07d2bc0970c348bb06fb63b1f82ddbf	addColumn tableName=REALM_ATTRIBUTE; update tableName=REALM_ATTRIBUTE; dropColumn columnName=VALUE, tableName=REALM_ATTRIBUTE; renameColumn newColumnName=VALUE, oldColumnName=VALUE_NEW, tableName=REALM_ATTRIBUTE		\N	4.33.0	\N	\N	5804754638
14.0.0-KEYCLOAK-11019	keycloak	META-INF/jpa-changelog-14.0.0.xml	2025-12-15 13:19:21.950517	97	EXECUTED	9:24fb8611e97f29989bea412aa38d12b7	createIndex indexName=IDX_OFFLINE_CSS_PRELOAD, tableName=OFFLINE_CLIENT_SESSION; createIndex indexName=IDX_OFFLINE_USS_BY_USER, tableName=OFFLINE_USER_SESSION; createIndex indexName=IDX_OFFLINE_USS_BY_USERSESS, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
14.0.0-KEYCLOAK-18286	keycloak	META-INF/jpa-changelog-14.0.0.xml	2025-12-15 13:19:21.954427	98	MARK_RAN	9:259f89014ce2506ee84740cbf7163aa7	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
14.0.0-KEYCLOAK-18286-revert	keycloak	META-INF/jpa-changelog-14.0.0.xml	2025-12-15 13:19:21.964336	99	MARK_RAN	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
14.0.0-KEYCLOAK-18286-supported-dbs	keycloak	META-INF/jpa-changelog-14.0.0.xml	2025-12-15 13:19:21.992019	100	EXECUTED	9:60ca84a0f8c94ec8c3504a5a3bc88ee8	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
14.0.0-KEYCLOAK-18286-unsupported-dbs	keycloak	META-INF/jpa-changelog-14.0.0.xml	2025-12-15 13:19:21.995098	101	MARK_RAN	9:d3d977031d431db16e2c181ce49d73e9	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
KEYCLOAK-17267-add-index-to-user-attributes	keycloak	META-INF/jpa-changelog-14.0.0.xml	2025-12-15 13:19:22.022151	102	EXECUTED	9:0b305d8d1277f3a89a0a53a659ad274c	createIndex indexName=IDX_USER_ATTRIBUTE_NAME, tableName=USER_ATTRIBUTE		\N	4.33.0	\N	\N	5804754638
KEYCLOAK-18146-add-saml-art-binding-identifier	keycloak	META-INF/jpa-changelog-14.0.0.xml	2025-12-15 13:19:22.026855	103	EXECUTED	9:2c374ad2cdfe20e2905a84c8fac48460	customChange		\N	4.33.0	\N	\N	5804754638
15.0.0-KEYCLOAK-18467	keycloak	META-INF/jpa-changelog-15.0.0.xml	2025-12-15 13:19:22.034405	104	EXECUTED	9:47a760639ac597360a8219f5b768b4de	addColumn tableName=REALM_LOCALIZATIONS; update tableName=REALM_LOCALIZATIONS; dropColumn columnName=TEXTS, tableName=REALM_LOCALIZATIONS; renameColumn newColumnName=TEXTS, oldColumnName=TEXTS_NEW, tableName=REALM_LOCALIZATIONS; addNotNullConstrai...		\N	4.33.0	\N	\N	5804754638
17.0.0-9562	keycloak	META-INF/jpa-changelog-17.0.0.xml	2025-12-15 13:19:22.060982	105	EXECUTED	9:a6272f0576727dd8cad2522335f5d99e	createIndex indexName=IDX_USER_SERVICE_ACCOUNT, tableName=USER_ENTITY		\N	4.33.0	\N	\N	5804754638
18.0.0-10625-IDX_ADMIN_EVENT_TIME	keycloak	META-INF/jpa-changelog-18.0.0.xml	2025-12-15 13:19:22.086766	106	EXECUTED	9:015479dbd691d9cc8669282f4828c41d	createIndex indexName=IDX_ADMIN_EVENT_TIME, tableName=ADMIN_EVENT_ENTITY		\N	4.33.0	\N	\N	5804754638
18.0.15-30992-index-consent	keycloak	META-INF/jpa-changelog-18.0.15.xml	2025-12-15 13:19:22.12362	107	EXECUTED	9:80071ede7a05604b1f4906f3bf3b00f0	createIndex indexName=IDX_USCONSENT_SCOPE_ID, tableName=USER_CONSENT_CLIENT_SCOPE		\N	4.33.0	\N	\N	5804754638
19.0.0-10135	keycloak	META-INF/jpa-changelog-19.0.0.xml	2025-12-15 13:19:22.128594	108	EXECUTED	9:9518e495fdd22f78ad6425cc30630221	customChange		\N	4.33.0	\N	\N	5804754638
20.0.0-12964-supported-dbs	keycloak	META-INF/jpa-changelog-20.0.0.xml	2025-12-15 13:19:22.153984	109	EXECUTED	9:e5f243877199fd96bcc842f27a1656ac	createIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE		\N	4.33.0	\N	\N	5804754638
20.0.0-12964-supported-dbs-edb-migration	keycloak	META-INF/jpa-changelog-20.0.0.xml	2025-12-15 13:19:22.184163	110	EXECUTED	9:a6b18a8e38062df5793edbe064f4aecd	dropIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE; createIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE		\N	4.33.0	\N	\N	5804754638
20.0.0-12964-unsupported-dbs	keycloak	META-INF/jpa-changelog-20.0.0.xml	2025-12-15 13:19:22.187178	111	MARK_RAN	9:1a6fcaa85e20bdeae0a9ce49b41946a5	createIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE		\N	4.33.0	\N	\N	5804754638
client-attributes-string-accomodation-fixed-pre-drop-index	keycloak	META-INF/jpa-changelog-20.0.0.xml	2025-12-15 13:19:22.193136	112	EXECUTED	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
client-attributes-string-accomodation-fixed	keycloak	META-INF/jpa-changelog-20.0.0.xml	2025-12-15 13:19:22.199617	113	EXECUTED	9:3f332e13e90739ed0c35b0b25b7822ca	addColumn tableName=CLIENT_ATTRIBUTES; update tableName=CLIENT_ATTRIBUTES; dropColumn columnName=VALUE, tableName=CLIENT_ATTRIBUTES; renameColumn newColumnName=VALUE, oldColumnName=VALUE_NEW, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
client-attributes-string-accomodation-fixed-post-create-index	keycloak	META-INF/jpa-changelog-20.0.0.xml	2025-12-15 13:19:22.202148	114	MARK_RAN	9:bd2bd0fc7768cf0845ac96a8786fa735	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
21.0.2-17277	keycloak	META-INF/jpa-changelog-21.0.2.xml	2025-12-15 13:19:22.206126	115	EXECUTED	9:7ee1f7a3fb8f5588f171fb9a6ab623c0	customChange		\N	4.33.0	\N	\N	5804754638
21.1.0-19404	keycloak	META-INF/jpa-changelog-21.1.0.xml	2025-12-15 13:19:22.252468	116	EXECUTED	9:3d7e830b52f33676b9d64f7f2b2ea634	modifyDataType columnName=DECISION_STRATEGY, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=LOGIC, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=POLICY_ENFORCE_MODE, tableName=RESOURCE_SERVER		\N	4.33.0	\N	\N	5804754638
21.1.0-19404-2	keycloak	META-INF/jpa-changelog-21.1.0.xml	2025-12-15 13:19:22.255773	117	MARK_RAN	9:627d032e3ef2c06c0e1f73d2ae25c26c	addColumn tableName=RESOURCE_SERVER_POLICY; update tableName=RESOURCE_SERVER_POLICY; dropColumn columnName=DECISION_STRATEGY, tableName=RESOURCE_SERVER_POLICY; renameColumn newColumnName=DECISION_STRATEGY, oldColumnName=DECISION_STRATEGY_NEW, tabl...		\N	4.33.0	\N	\N	5804754638
22.0.0-17484-updated	keycloak	META-INF/jpa-changelog-22.0.0.xml	2025-12-15 13:19:22.259963	118	EXECUTED	9:90af0bfd30cafc17b9f4d6eccd92b8b3	customChange		\N	4.33.0	\N	\N	5804754638
23.0.0-12062	keycloak	META-INF/jpa-changelog-23.0.0.xml	2025-12-15 13:19:22.268806	120	EXECUTED	9:2168fbe728fec46ae9baf15bf80927b8	addColumn tableName=COMPONENT_CONFIG; update tableName=COMPONENT_CONFIG; dropColumn columnName=VALUE, tableName=COMPONENT_CONFIG; renameColumn newColumnName=VALUE, oldColumnName=VALUE_NEW, tableName=COMPONENT_CONFIG		\N	4.33.0	\N	\N	5804754638
23.0.0-17258	keycloak	META-INF/jpa-changelog-23.0.0.xml	2025-12-15 13:19:22.273948	121	EXECUTED	9:36506d679a83bbfda85a27ea1864dca8	addColumn tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	5804754638
24.0.0-9758	keycloak	META-INF/jpa-changelog-24.0.0.xml	2025-12-15 13:19:22.371265	122	EXECUTED	9:502c557a5189f600f0f445a9b49ebbce	addColumn tableName=USER_ATTRIBUTE; addColumn tableName=FED_USER_ATTRIBUTE; createIndex indexName=USER_ATTR_LONG_VALUES, tableName=USER_ATTRIBUTE; createIndex indexName=FED_USER_ATTR_LONG_VALUES, tableName=FED_USER_ATTRIBUTE; createIndex indexName...		\N	4.33.0	\N	\N	5804754638
24.0.0-9758-2	keycloak	META-INF/jpa-changelog-24.0.0.xml	2025-12-15 13:19:22.375389	123	EXECUTED	9:bf0fdee10afdf597a987adbf291db7b2	customChange		\N	4.33.0	\N	\N	5804754638
24.0.0-26618-drop-index-if-present	keycloak	META-INF/jpa-changelog-24.0.0.xml	2025-12-15 13:19:22.380713	124	MARK_RAN	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
24.0.0-26618-reindex	keycloak	META-INF/jpa-changelog-24.0.0.xml	2025-12-15 13:19:22.405717	125	EXECUTED	9:08707c0f0db1cef6b352db03a60edc7f	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
24.0.0-26618-edb-migration	keycloak	META-INF/jpa-changelog-24.0.0.xml	2025-12-15 13:19:22.433412	126	EXECUTED	9:2f684b29d414cd47efe3a3599f390741	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES; createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
24.0.2-27228	keycloak	META-INF/jpa-changelog-24.0.2.xml	2025-12-15 13:19:22.43806	127	EXECUTED	9:eaee11f6b8aa25d2cc6a84fb86fc6238	customChange		\N	4.33.0	\N	\N	5804754638
24.0.2-27967-drop-index-if-present	keycloak	META-INF/jpa-changelog-24.0.2.xml	2025-12-15 13:19:22.440955	128	MARK_RAN	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
24.0.2-27967-reindex	keycloak	META-INF/jpa-changelog-24.0.2.xml	2025-12-15 13:19:22.444177	129	MARK_RAN	9:d3d977031d431db16e2c181ce49d73e9	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-tables	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.450681	130	EXECUTED	9:deda2df035df23388af95bbd36c17cef	addColumn tableName=OFFLINE_USER_SESSION; addColumn tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-index-creation	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.478715	131	EXECUTED	9:3e96709818458ae49f3c679ae58d263a	createIndex indexName=IDX_OFFLINE_USS_BY_LAST_SESSION_REFRESH, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-index-cleanup-uss-createdon	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.488175	132	EXECUTED	9:78ab4fc129ed5e8265dbcc3485fba92f	dropIndex indexName=IDX_OFFLINE_USS_CREATEDON, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-index-cleanup-uss-preload	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.497017	133	EXECUTED	9:de5f7c1f7e10994ed8b62e621d20eaab	dropIndex indexName=IDX_OFFLINE_USS_PRELOAD, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-index-cleanup-uss-by-usersess	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.505863	134	EXECUTED	9:6eee220d024e38e89c799417ec33667f	dropIndex indexName=IDX_OFFLINE_USS_BY_USERSESS, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-index-cleanup-css-preload	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.514356	135	EXECUTED	9:5411d2fb2891d3e8d63ddb55dfa3c0c9	dropIndex indexName=IDX_OFFLINE_CSS_PRELOAD, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-index-2-mysql	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.516995	136	MARK_RAN	9:b7ef76036d3126bb83c2423bf4d449d6	createIndex indexName=IDX_OFFLINE_USS_BY_BROKER_SESSION_ID, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-28265-index-2-not-mysql	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.542488	137	EXECUTED	9:23396cf51ab8bc1ae6f0cac7f9f6fcf7	createIndex indexName=IDX_OFFLINE_USS_BY_BROKER_SESSION_ID, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	5804754638
25.0.0-org	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.582453	138	EXECUTED	9:5c859965c2c9b9c72136c360649af157	createTable tableName=ORG; addUniqueConstraint constraintName=UK_ORG_NAME, tableName=ORG; addUniqueConstraint constraintName=UK_ORG_GROUP, tableName=ORG; createTable tableName=ORG_DOMAIN		\N	4.33.0	\N	\N	5804754638
unique-consentuser	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.599464	139	EXECUTED	9:5857626a2ea8767e9a6c66bf3a2cb32f	customChange; dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_LOCAL_CONSENT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_EXTERNAL_CONSENT, tableName=...		\N	4.33.0	\N	\N	5804754638
unique-consentuser-edb-migration	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.606697	140	MARK_RAN	9:5857626a2ea8767e9a6c66bf3a2cb32f	customChange; dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_LOCAL_CONSENT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_EXTERNAL_CONSENT, tableName=...		\N	4.33.0	\N	\N	5804754638
unique-consentuser-mysql	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.609629	141	MARK_RAN	9:b79478aad5adaa1bc428e31563f55e8e	customChange; dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_LOCAL_CONSENT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_EXTERNAL_CONSENT, tableName=...		\N	4.33.0	\N	\N	5804754638
25.0.0-28861-index-creation	keycloak	META-INF/jpa-changelog-25.0.0.xml	2025-12-15 13:19:22.654127	142	EXECUTED	9:b9acb58ac958d9ada0fe12a5d4794ab1	createIndex indexName=IDX_PERM_TICKET_REQUESTER, tableName=RESOURCE_SERVER_PERM_TICKET; createIndex indexName=IDX_PERM_TICKET_OWNER, tableName=RESOURCE_SERVER_PERM_TICKET		\N	4.33.0	\N	\N	5804754638
26.0.0-org-alias	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.665124	143	EXECUTED	9:6ef7d63e4412b3c2d66ed179159886a4	addColumn tableName=ORG; update tableName=ORG; addNotNullConstraint columnName=ALIAS, tableName=ORG; addUniqueConstraint constraintName=UK_ORG_ALIAS, tableName=ORG		\N	4.33.0	\N	\N	5804754638
26.0.0-org-group	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.688039	144	EXECUTED	9:da8e8087d80ef2ace4f89d8c5b9ca223	addColumn tableName=KEYCLOAK_GROUP; update tableName=KEYCLOAK_GROUP; addNotNullConstraint columnName=TYPE, tableName=KEYCLOAK_GROUP; customChange		\N	4.33.0	\N	\N	5804754638
26.0.0-org-indexes	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.715095	145	EXECUTED	9:79b05dcd610a8c7f25ec05135eec0857	createIndex indexName=IDX_ORG_DOMAIN_ORG_ID, tableName=ORG_DOMAIN		\N	4.33.0	\N	\N	5804754638
26.0.0-org-group-membership	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.72132	146	EXECUTED	9:a6ace2ce583a421d89b01ba2a28dc2d4	addColumn tableName=USER_GROUP_MEMBERSHIP; update tableName=USER_GROUP_MEMBERSHIP; addNotNullConstraint columnName=MEMBERSHIP_TYPE, tableName=USER_GROUP_MEMBERSHIP		\N	4.33.0	\N	\N	5804754638
31296-persist-revoked-access-tokens	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.731302	147	EXECUTED	9:64ef94489d42a358e8304b0e245f0ed4	createTable tableName=REVOKED_TOKEN; addPrimaryKey constraintName=CONSTRAINT_RT, tableName=REVOKED_TOKEN		\N	4.33.0	\N	\N	5804754638
31725-index-persist-revoked-access-tokens	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.760787	148	EXECUTED	9:b994246ec2bf7c94da881e1d28782c7b	createIndex indexName=IDX_REV_TOKEN_ON_EXPIRE, tableName=REVOKED_TOKEN		\N	4.33.0	\N	\N	5804754638
26.0.0-idps-for-login	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.813754	149	EXECUTED	9:51f5fffadf986983d4bd59582c6c1604	addColumn tableName=IDENTITY_PROVIDER; createIndex indexName=IDX_IDP_REALM_ORG, tableName=IDENTITY_PROVIDER; createIndex indexName=IDX_IDP_FOR_LOGIN, tableName=IDENTITY_PROVIDER; customChange		\N	4.33.0	\N	\N	5804754638
26.0.0-32583-drop-redundant-index-on-client-session	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.821391	150	EXECUTED	9:24972d83bf27317a055d234187bb4af9	dropIndex indexName=IDX_US_SESS_ID_ON_CL_SESS, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	5804754638
26.0.0.32582-remove-tables-user-session-user-session-note-and-client-session	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.83586	151	EXECUTED	9:febdc0f47f2ed241c59e60f58c3ceea5	dropTable tableName=CLIENT_SESSION_ROLE; dropTable tableName=CLIENT_SESSION_NOTE; dropTable tableName=CLIENT_SESSION_PROT_MAPPER; dropTable tableName=CLIENT_SESSION_AUTH_STATUS; dropTable tableName=CLIENT_USER_SESSION_NOTE; dropTable tableName=CLI...		\N	4.33.0	\N	\N	5804754638
26.0.0-33201-org-redirect-url	keycloak	META-INF/jpa-changelog-26.0.0.xml	2025-12-15 13:19:22.841136	152	EXECUTED	9:4d0e22b0ac68ebe9794fa9cb752ea660	addColumn tableName=ORG		\N	4.33.0	\N	\N	5804754638
29399-jdbc-ping-default	keycloak	META-INF/jpa-changelog-26.1.0.xml	2025-12-15 13:19:22.856204	153	EXECUTED	9:007dbe99d7203fca403b89d4edfdf21e	createTable tableName=JGROUPS_PING; addPrimaryKey constraintName=CONSTRAINT_JGROUPS_PING, tableName=JGROUPS_PING		\N	4.33.0	\N	\N	5804754638
26.1.0-34013	keycloak	META-INF/jpa-changelog-26.1.0.xml	2025-12-15 13:19:22.863335	154	EXECUTED	9:e6b686a15759aef99a6d758a5c4c6a26	addColumn tableName=ADMIN_EVENT_ENTITY		\N	4.33.0	\N	\N	5804754638
26.1.0-34380	keycloak	META-INF/jpa-changelog-26.1.0.xml	2025-12-15 13:19:22.869209	155	EXECUTED	9:ac8b9edb7c2b6c17a1c7a11fcf5ccf01	dropTable tableName=USERNAME_LOGIN_FAILURE		\N	4.33.0	\N	\N	5804754638
26.2.0-36750	keycloak	META-INF/jpa-changelog-26.2.0.xml	2025-12-15 13:19:22.883551	156	EXECUTED	9:b49ce951c22f7eb16480ff085640a33a	createTable tableName=SERVER_CONFIG		\N	4.33.0	\N	\N	5804754638
26.2.0-26106	keycloak	META-INF/jpa-changelog-26.2.0.xml	2025-12-15 13:19:22.889327	157	EXECUTED	9:b5877d5dab7d10ff3a9d209d7beb6680	addColumn tableName=CREDENTIAL		\N	4.33.0	\N	\N	5804754638
26.2.6-39866-duplicate	keycloak	META-INF/jpa-changelog-26.2.6.xml	2025-12-15 13:19:22.893645	158	EXECUTED	9:1dc67ccee24f30331db2cba4f372e40e	customChange		\N	4.33.0	\N	\N	5804754638
26.2.6-39866-uk	keycloak	META-INF/jpa-changelog-26.2.6.xml	2025-12-15 13:19:22.903114	159	EXECUTED	9:b70b76f47210cf0a5f4ef0e219eac7cd	addUniqueConstraint constraintName=UK_MIGRATION_VERSION, tableName=MIGRATION_MODEL		\N	4.33.0	\N	\N	5804754638
26.2.6-40088-duplicate	keycloak	META-INF/jpa-changelog-26.2.6.xml	2025-12-15 13:19:22.907839	160	EXECUTED	9:cc7e02ed69ab31979afb1982f9670e8f	customChange		\N	4.33.0	\N	\N	5804754638
26.2.6-40088-uk	keycloak	META-INF/jpa-changelog-26.2.6.xml	2025-12-15 13:19:22.917884	161	EXECUTED	9:5bb848128da7bc4595cc507383325241	addUniqueConstraint constraintName=UK_MIGRATION_UPDATE_TIME, tableName=MIGRATION_MODEL		\N	4.33.0	\N	\N	5804754638
26.3.0-groups-description	keycloak	META-INF/jpa-changelog-26.3.0.xml	2025-12-15 13:19:22.92766	162	EXECUTED	9:e1a3c05574326fb5b246b73b9a4c4d49	addColumn tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	5804754638
26.4.0-40933-saml-encryption-attributes	keycloak	META-INF/jpa-changelog-26.4.0.xml	2025-12-15 13:19:22.931505	163	EXECUTED	9:7e9eaba362ca105efdda202303a4fe49	customChange		\N	4.33.0	\N	\N	5804754638
26.4.0-51321	keycloak	META-INF/jpa-changelog-26.4.0.xml	2025-12-15 13:19:22.961429	164	EXECUTED	9:34bab2bc56f75ffd7e347c580874e306	createIndex indexName=IDX_EVENT_ENTITY_USER_ID_TYPE, tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	5804754638
40343-workflow-state-table	keycloak	META-INF/jpa-changelog-26.4.0.xml	2025-12-15 13:19:23.026505	165	EXECUTED	9:ed3ab4723ceed210e5b5e60ac4562106	createTable tableName=WORKFLOW_STATE; addPrimaryKey constraintName=PK_WORKFLOW_STATE, tableName=WORKFLOW_STATE; addUniqueConstraint constraintName=UQ_WORKFLOW_RESOURCE, tableName=WORKFLOW_STATE; createIndex indexName=IDX_WORKFLOW_STATE_STEP, table...		\N	4.33.0	\N	\N	5804754638
26.5.0-index-offline-css-by-client	keycloak	META-INF/jpa-changelog-26.5.0.xml	2025-12-15 13:19:23.05634	166	EXECUTED	9:383e981ce95d16e32af757b7998820f7	createIndex indexName=IDX_OFFLINE_CSS_BY_CLIENT, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	5804754638
26.5.0-index-offline-css-by-client-storage-provider	keycloak	META-INF/jpa-changelog-26.5.0.xml	2025-12-15 13:19:23.087532	167	EXECUTED	9:f5bc200e6fa7d7e483854dee535ca425	createIndex indexName=IDX_OFFLINE_CSS_BY_CLIENT_STORAGE_PROVIDER, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	5804754638
\.


--
-- Data for Name: databasechangeloglock; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.databasechangeloglock (id, locked, lockgranted, lockedby) FROM stdin;
1	f	\N	\N
1000	f	\N	\N
\.


--
-- Data for Name: default_client_scope; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.default_client_scope (realm_id, scope_id, default_scope) FROM stdin;
955a00d0-1411-4e86-8ef2-bdedffd7a66f	17958855-2814-4159-b3a1-5b40cdaeebe6	f
955a00d0-1411-4e86-8ef2-bdedffd7a66f	3e34312e-2989-4347-a934-b60dfd2d544c	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	6e404f54-922f-4145-bb29-a9e21a8edcf9	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	77258524-6f0f-4406-b315-7ddc4796c00d	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	653a25e7-40d9-4b92-a25e-bb8455b6ebdf	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	40d8effa-ea43-4033-a14c-357a47b72d7c	f
955a00d0-1411-4e86-8ef2-bdedffd7a66f	d8c9cf61-7cc8-4290-89b2-ab17995ff99d	f
955a00d0-1411-4e86-8ef2-bdedffd7a66f	086a4221-efa4-40b1-9f46-97e5d68fdf20	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	61816b49-1207-4d27-852b-b14874c5eddf	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	84a15d18-e232-4be0-86ea-3458c0dab9b3	f
955a00d0-1411-4e86-8ef2-bdedffd7a66f	a8cefe79-91a3-45ea-b561-5aff65223896	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	30aca326-0e4f-4226-bfa0-a7c546848c95	t
955a00d0-1411-4e86-8ef2-bdedffd7a66f	d3507a8a-46c0-4ae7-9011-fc52c5207e07	f
27d57df0-0794-4e96-92ac-85b802200864	67bc1745-9981-4d04-88a8-871d88a7e522	t
27d57df0-0794-4e96-92ac-85b802200864	df6a0a58-c6a8-4534-83b1-7b52b3aa62f9	t
27d57df0-0794-4e96-92ac-85b802200864	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26	t
27d57df0-0794-4e96-92ac-85b802200864	1d2bd933-a550-4d11-aa78-258954290a9c	t
27d57df0-0794-4e96-92ac-85b802200864	147f68f2-1deb-489e-90c1-1f0a216aca17	t
27d57df0-0794-4e96-92ac-85b802200864	38b9f19b-48c5-49f2-a73f-07a8404f2c48	t
27d57df0-0794-4e96-92ac-85b802200864	2f4c6846-d426-4d40-a15f-1acd7351a946	t
27d57df0-0794-4e96-92ac-85b802200864	c87139e6-dacf-4a3b-ab0e-c74899e16e31	t
27d57df0-0794-4e96-92ac-85b802200864	d512f187-3acb-4f8a-a985-41a797d3e53f	f
27d57df0-0794-4e96-92ac-85b802200864	364cdea3-6979-46a0-85f1-222797349de4	f
27d57df0-0794-4e96-92ac-85b802200864	5b61aded-f5c8-4ad3-b779-065520195daa	f
27d57df0-0794-4e96-92ac-85b802200864	3f34b32f-25ee-4770-979c-918b005c06c6	f
27d57df0-0794-4e96-92ac-85b802200864	54b31ac9-dea0-43d0-aa3a-1f691b495492	f
\.


--
-- Data for Name: event_entity; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.event_entity (id, client_id, details_json, error, ip_address, realm_id, session_id, event_time, type, user_id, details_json_long_value) FROM stdin;
\.


--
-- Data for Name: fed_user_attribute; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.fed_user_attribute (id, name, user_id, realm_id, storage_provider_id, value, long_value_hash, long_value_hash_lower_case, long_value) FROM stdin;
\.


--
-- Data for Name: fed_user_consent; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.fed_user_consent (id, client_id, user_id, realm_id, storage_provider_id, created_date, last_updated_date, client_storage_provider, external_client_id) FROM stdin;
\.


--
-- Data for Name: fed_user_consent_cl_scope; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.fed_user_consent_cl_scope (user_consent_id, scope_id) FROM stdin;
\.


--
-- Data for Name: fed_user_credential; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.fed_user_credential (id, salt, type, created_date, user_id, realm_id, storage_provider_id, user_label, secret_data, credential_data, priority) FROM stdin;
\.


--
-- Data for Name: fed_user_group_membership; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.fed_user_group_membership (group_id, user_id, realm_id, storage_provider_id) FROM stdin;
\.


--
-- Data for Name: fed_user_required_action; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.fed_user_required_action (required_action, user_id, realm_id, storage_provider_id) FROM stdin;
\.


--
-- Data for Name: fed_user_role_mapping; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.fed_user_role_mapping (role_id, user_id, realm_id, storage_provider_id) FROM stdin;
\.


--
-- Data for Name: federated_identity; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.federated_identity (identity_provider, realm_id, federated_user_id, federated_username, token, user_id) FROM stdin;
\.


--
-- Data for Name: federated_user; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.federated_user (id, storage_provider_id, realm_id) FROM stdin;
\.


--
-- Data for Name: group_attribute; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.group_attribute (id, name, value, group_id) FROM stdin;
\.


--
-- Data for Name: group_role_mapping; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.group_role_mapping (role_id, group_id) FROM stdin;
\.


--
-- Data for Name: identity_provider; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.identity_provider (internal_id, enabled, provider_alias, provider_id, store_token, authenticate_by_default, realm_id, add_token_role, trust_email, first_broker_login_flow_id, post_broker_login_flow_id, provider_display_name, link_only, organization_id, hide_on_login) FROM stdin;
\.


--
-- Data for Name: identity_provider_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.identity_provider_config (identity_provider_id, value, name) FROM stdin;
\.


--
-- Data for Name: identity_provider_mapper; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.identity_provider_mapper (id, name, idp_alias, idp_mapper_name, realm_id) FROM stdin;
\.


--
-- Data for Name: idp_mapper_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.idp_mapper_config (idp_mapper_id, value, name) FROM stdin;
\.


--
-- Data for Name: jgroups_ping; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.jgroups_ping (address, name, cluster_name, ip, coord) FROM stdin;
\.


--
-- Data for Name: keycloak_group; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.keycloak_group (id, name, parent_group, realm_id, type, description) FROM stdin;
\.


--
-- Data for Name: keycloak_role; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.keycloak_role (id, client_realm_constraint, client_role, description, name, realm_id, client, realm) FROM stdin;
74bbf2b8-0473-4e83-a487-af069f08b188	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	${role_default-roles}	default-roles-master	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N	\N
417a29f4-aa8b-4560-9f73-eafc6a417349	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	${role_admin}	admin	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N	\N
abee5d94-e14e-4da8-a52b-fc8bfee803e1	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	${role_create-realm}	create-realm	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N	\N
b8d87e42-d5fa-4f0d-9f71-8bb47a6f19e4	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_create-client}	create-client	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
bc60158b-e3c0-4741-93aa-c57ed824bf24	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_view-realm}	view-realm	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
fe17e097-a79b-4b77-926d-7b610a73779e	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_view-users}	view-users	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
bc81c759-7eda-486e-8fa6-f0285ec5526d	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_view-clients}	view-clients	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
97576643-c60d-4ec3-8ce0-22e15900a8af	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_view-events}	view-events	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
b0f23d7f-184c-42ff-80a9-a870088b76ec	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_view-identity-providers}	view-identity-providers	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
77aad39e-f806-4ef8-bd46-9aa2ca9274ef	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_view-authorization}	view-authorization	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
6d9cd6b3-aad4-4162-a1c4-f143daa199cf	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_manage-realm}	manage-realm	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
f2b96aa3-b8b2-4503-bbde-550296c1cb3d	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_manage-users}	manage-users	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
770148f1-42ee-4101-8665-4c08fe83adcd	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_manage-clients}	manage-clients	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
983f5ad0-b1b9-431f-a471-a636ac43e15f	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_manage-events}	manage-events	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
9ed69905-e59e-4908-ad1b-0944270a1d74	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_manage-identity-providers}	manage-identity-providers	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
ffe4c690-8b6e-45f0-b78c-8214815b3402	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_manage-authorization}	manage-authorization	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
c464e592-eed4-43ac-87c5-87fba272e40a	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_query-users}	query-users	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
a6083528-1902-4af9-b3f6-72525c4bb7b1	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_query-clients}	query-clients	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
234b1742-3ab8-44b2-ba89-8a14f7a7dece	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_query-realms}	query-realms	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
7184fb13-9253-47a6-a0c4-f81c9f45b808	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_query-groups}	query-groups	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
dfa15bab-46e0-4d19-8321-7f1014329997	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_view-profile}	view-profile	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
60f5bc18-fe0d-43bd-adcf-cdc636e356f2	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_manage-account}	manage-account	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
1021a5c2-2e5f-4c81-93fd-0282b86c6297	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_manage-account-links}	manage-account-links	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
4213b52c-e8ac-4ae8-a3a1-2a44f28e01c9	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_view-applications}	view-applications	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
eb8e5a6a-849b-4d16-86e9-4979836e4676	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_view-consent}	view-consent	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
122cb6c9-b10f-40eb-b3c0-34d1308f4a0e	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_manage-consent}	manage-consent	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
e861c14b-e90b-472c-bdeb-e58d513389ff	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_view-groups}	view-groups	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
8c178b73-6ae4-490e-9bed-93b3965de957	0f0ec0f5-6e68-4308-8b92-25489a9feacf	t	${role_delete-account}	delete-account	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0f0ec0f5-6e68-4308-8b92-25489a9feacf	\N
4003e805-0345-4894-b3ed-0ec1566ac4a1	021ad7d4-8c07-4560-932f-356c274b52f3	t	${role_read-token}	read-token	955a00d0-1411-4e86-8ef2-bdedffd7a66f	021ad7d4-8c07-4560-932f-356c274b52f3	\N
c32377a3-fca7-474f-82dd-4b9341a45d8e	aeb1d986-2bef-405c-a65d-c190561c2f31	t	${role_impersonation}	impersonation	955a00d0-1411-4e86-8ef2-bdedffd7a66f	aeb1d986-2bef-405c-a65d-c190561c2f31	\N
7a38715c-ec4b-4953-86f2-fa52ad0cea78	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	${role_offline-access}	offline_access	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N	\N
126087ae-3a7d-4f40-8437-9b63d998a259	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	${role_uma_authorization}	uma_authorization	955a00d0-1411-4e86-8ef2-bdedffd7a66f	\N	\N
39c3feae-b3f5-49b1-a6cf-1f91960d022d	27d57df0-0794-4e96-92ac-85b802200864	f	${role_default-roles}	default-roles-fhir-auth	27d57df0-0794-4e96-92ac-85b802200864	\N	\N
a3155255-4da9-456a-b035-d9df8f93820d	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_create-client}	create-client	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
bf2799d2-4514-466f-9b2f-fe047aaecacd	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_view-realm}	view-realm	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
81786bf9-dee9-42e1-b8be-911a2547d2d8	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_view-users}	view-users	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
7c2887a1-b59f-4e40-8e82-9b500a226705	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_view-clients}	view-clients	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
3204aa25-9901-46fb-902a-e85f4d58bbe3	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_view-events}	view-events	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
0b8d3d20-6f20-486a-adff-ead7e8df1718	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_view-identity-providers}	view-identity-providers	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
ae2492d8-5ca8-404e-8e4f-46748b6e9d0f	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_view-authorization}	view-authorization	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
79814634-1fb7-4738-bb0c-f3a26ce8405b	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_manage-realm}	manage-realm	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
5e8eea9f-553c-4b02-870c-408103d739e7	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_manage-users}	manage-users	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
be091733-a521-4e90-8a3e-d59520ec109e	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_manage-clients}	manage-clients	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
46b7408d-3faa-45af-8d1b-01af85e25b2c	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_manage-events}	manage-events	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
89c2f2e3-f8ce-4e01-aa56-d4d89566c479	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_manage-identity-providers}	manage-identity-providers	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
01db9827-1af9-4a62-8dfa-b5f8a5e0aa5a	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_manage-authorization}	manage-authorization	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
19bd2559-cac7-4f52-a726-e8881068c85b	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_query-users}	query-users	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
3648783f-d2a9-4016-befd-880f5ee43e9e	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_query-clients}	query-clients	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
71d02f81-09a2-4706-9bce-4c01a0199e2b	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_query-realms}	query-realms	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
2f154e09-1aa6-4d54-9110-938d903abf88	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_query-groups}	query-groups	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
52834c63-0987-45b9-8394-1c0cb9e31f22	27d57df0-0794-4e96-92ac-85b802200864	f	${role_offline-access}	offline_access	27d57df0-0794-4e96-92ac-85b802200864	\N	\N
12d01785-a93c-419d-8161-71201cfc13a2	27d57df0-0794-4e96-92ac-85b802200864	f	${role_uma_authorization}	uma_authorization	27d57df0-0794-4e96-92ac-85b802200864	\N	\N
b627b089-53d9-44f8-a4af-5e013848ac9a	27d57df0-0794-4e96-92ac-85b802200864	f	Healthcare provider who can access patient data with permission	Doctor	27d57df0-0794-4e96-92ac-85b802200864	\N	\N
1c35c95b-4c5c-4645-8eba-ef030193f04e	27d57df0-0794-4e96-92ac-85b802200864	f	Standard patient user who can access their own health data	Patient	27d57df0-0794-4e96-92ac-85b802200864	\N	\N
9db8f464-eccb-4967-be8d-7e7d934a661e	27d57df0-0794-4e96-92ac-85b802200864	f	System administrator with full access to all resources	Administrator	27d57df0-0794-4e96-92ac-85b802200864	\N	\N
6758f8e6-bafe-4e07-a73c-dd46d5de4aa8	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_view-authorization}	view-authorization	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
d9388adb-1d17-4c6e-a982-191c08c6f844	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_view-users}	view-users	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
bccf785d-7c5d-4f0b-a119-5cb0ea5758a8	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_manage-realm}	manage-realm	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
9cbfe1f6-ffae-474f-a00b-3752475a19fc	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_manage-users}	manage-users	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
a1bf2364-7a57-41e2-a69a-74209fcf6579	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_query-users}	query-users	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
567adb13-3c8d-4bf7-9ae1-34a5699882d9	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_realm-admin}	realm-admin	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
3c1ee422-a51f-4001-a95b-a70a6449052e	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_manage-events}	manage-events	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
9a27d858-0e46-4baf-9657-d5e38d56c4fe	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_manage-identity-providers}	manage-identity-providers	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
c08c5ffe-b64d-432c-b7ee-5fcb4086bb35	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_view-clients}	view-clients	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
be5bf3f8-5751-4915-a9a5-aef3a75b2b5e	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_view-events}	view-events	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
4627e2ab-c964-4065-9fc4-9e1dd183c262	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_create-client}	create-client	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
3bf13298-a242-453e-af63-b610281d5627	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_impersonation}	impersonation	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
cb351478-8b13-47c5-be79-6ac3af3dd6d0	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_query-groups}	query-groups	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
57a7ddb3-80d7-4da5-8629-22f931f13916	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_query-clients}	query-clients	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
33975d52-f850-4929-acfe-7543a9dc4312	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_view-realm}	view-realm	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
2eccc0fe-1c76-4338-a188-e22f1c7271e5	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_manage-authorization}	manage-authorization	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
74da0329-b34a-43e1-b14b-0791997e6af2	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_view-identity-providers}	view-identity-providers	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
cb2eea3d-fe96-4004-bbd2-5784a158867c	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_manage-clients}	manage-clients	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
ebc6b236-f812-41a3-a572-1dbfdcd50a1e	c1926955-f77b-4a15-8be9-fbab2b1f504f	t	${role_query-realms}	query-realms	27d57df0-0794-4e96-92ac-85b802200864	c1926955-f77b-4a15-8be9-fbab2b1f504f	\N
b6629199-585d-40b5-b152-867da4feec38	f637d925-d634-4b92-ad79-fb1b387b3e2e	t	\N	uma_protection	27d57df0-0794-4e96-92ac-85b802200864	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
109bb8eb-0a98-40e8-902e-147142204423	a6df953f-60f9-46b6-83d9-0a81b62d04a5	t	${role_read-token}	read-token	27d57df0-0794-4e96-92ac-85b802200864	a6df953f-60f9-46b6-83d9-0a81b62d04a5	\N
348968f5-aa47-415e-99ce-5d178c7523a6	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_view-applications}	view-applications	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
7181db14-7921-4e28-a3c4-93dee425c88d	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_delete-account}	delete-account	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
8d8c96cd-4220-4b4c-8b1a-11d284791592	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_view-groups}	view-groups	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
020c24b4-383a-4463-9c50-8107c2b257e1	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_view-consent}	view-consent	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
8c4fb8e5-3b13-40fa-9de3-84f178372a1b	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_view-profile}	view-profile	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
22b8abad-460c-464d-afae-3b6a2380d7d0	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_manage-account}	manage-account	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
df77a96a-da8d-4ec3-8598-9ca5ce6c5fd9	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_manage-consent}	manage-consent	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
85f1cc16-c9c7-44e3-a710-698ec79178b8	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	t	${role_manage-account-links}	manage-account-links	27d57df0-0794-4e96-92ac-85b802200864	c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	\N
99bee062-a066-43aa-bcd6-f49a57501d37	1516ec14-8f75-485c-82c7-0df5c1d360d1	t	${role_impersonation}	impersonation	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1516ec14-8f75-485c-82c7-0df5c1d360d1	\N
\.


--
-- Data for Name: migration_model; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.migration_model (id, version, update_time) FROM stdin;
t1m6j	26.4.6	1765804764
\.


--
-- Data for Name: offline_client_session; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.offline_client_session (user_session_id, client_id, offline_flag, "timestamp", data, client_storage_provider, external_client_id, version) FROM stdin;
3932f0cd-3008-5328-18d5-104cef28a533	247c0e1e-e295-45ea-904d-824e58645759	0	1769540132	{"authMethod":"openid-connect","redirectUri":"http://localhost:8080/admin/master/console/#/FHIR-Auth/realms","notes":{"clientId":"247c0e1e-e295-45ea-904d-824e58645759","iss":"http://localhost:8080/realms/master","startedAt":"1769535656","response_type":"code","level-of-authentication":"-1","code_challenge_method":"S256","nonce":"58405ba2-6372-4577-aea5-829faa0dcf83","response_mode":"query","scope":"openid","userSessionStartedAt":"1769535656","redirect_uri":"http://localhost:8080/admin/master/console/#/FHIR-Auth/realms","state":"09b00bc0-d6dd-4ef1-9a31-40be22331bc4","code_challenge":"8UsH2EZU5XHfjBd6GmFIW9xo-A2xsdIemgL-Ceje1q4"}}	local	local	13
\.


--
-- Data for Name: offline_user_session; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.offline_user_session (user_session_id, user_id, realm_id, created_on, offline_flag, data, last_session_refresh, broker_session_id, version) FROM stdin;
3932f0cd-3008-5328-18d5-104cef28a533	b9db48fc-0c61-4a58-adc4-60a3f190fd93	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1769535656	0	{"ipAddress":"172.18.0.1","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMTguMC4xIiwib3MiOiJXaW5kb3dzIiwib3NWZXJzaW9uIjoiMTAiLCJicm93c2VyIjoiQ2hyb21lLzE0My4wLjAiLCJkZXZpY2UiOiJPdGhlciIsImxhc3RBY2Nlc3MiOjAsIm1vYmlsZSI6ZmFsc2V9","AUTH_TIME":"1769535656","authenticators-completed":"{\\"d757214b-c9c4-4bf5-9430-07b03e690bbc\\":1769535656}"},"state":"LOGGED_IN"}	1769540132	\N	13
\.


--
-- Data for Name: org; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.org (id, enabled, realm_id, group_id, name, description, alias, redirect_url) FROM stdin;
\.


--
-- Data for Name: org_domain; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.org_domain (id, name, verified, org_id) FROM stdin;
\.


--
-- Data for Name: policy_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.policy_config (policy_id, name, value) FROM stdin;
98d17cf6-af9d-4ec2-bf22-3ebc75f6043c	clients	["f637d925-d634-4b92-ad79-fb1b387b3e2e"]
0b3e0ae3-9d52-4e27-9cce-4df78f6f1b13	fetchRoles	false
0b3e0ae3-9d52-4e27-9cce-4df78f6f1b13	roles	[{"id":"1c35c95b-4c5c-4645-8eba-ef030193f04e","required":true}]
f0097b3d-896d-4bca-a1a6-2f23f67c4179	fetchRoles	false
f0097b3d-896d-4bca-a1a6-2f23f67c4179	roles	[{"id":"b627b089-53d9-44f8-a4af-5e013848ac9a","required":true}]
cf031263-2240-4e3a-aa66-435d8be13bda	fetchRoles	false
cf031263-2240-4e3a-aa66-435d8be13bda	roles	[{"id":"9db8f464-eccb-4967-be8d-7e7d934a661e","required":true}]
efd93021-7e76-4202-ba03-d89330a48f66	defaultResourceType	
647de62c-fbb7-4310-a5b6-3e4fc20d1c7d	defaultResourceType	Patient
b3394fda-9dda-4f92-b07c-e2cbe35c2ec8	defaultResourceType	Condition
feb85689-e557-409d-a01a-dd606952baf3	defaultResourceType	MediactionStatement
b142bc58-efb0-448d-9203-66894c6aac16	users	["499edbce-5fcd-4a08-9ac0-113864a2afa3"]
76050c35-6e2e-4ef8-8769-b4c6354116dc	users	["97503f80-1f4f-4ae6-8b58-eb50a082acf9"]
\.


--
-- Data for Name: protocol_mapper; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.protocol_mapper (id, name, protocol, protocol_mapper_name, client_id, client_scope_id) FROM stdin;
5607b5cc-0efe-4721-8ede-66697aaace5f	audience resolve	openid-connect	oidc-audience-resolve-mapper	acf59302-35a1-4e76-895c-f9a9c7234692	\N
ab9f0dbc-2285-4961-9d8c-024289a9b481	locale	openid-connect	oidc-usermodel-attribute-mapper	247c0e1e-e295-45ea-904d-824e58645759	\N
b89eb0f1-36b9-4557-80bf-f587ad10b7af	role list	saml	saml-role-list-mapper	\N	3e34312e-2989-4347-a934-b60dfd2d544c
4715c8b2-09e7-43a0-afd9-f6787703ae06	organization	saml	saml-organization-membership-mapper	\N	6e404f54-922f-4145-bb29-a9e21a8edcf9
838e6a17-92b5-46ae-a2f6-ebcbfce2b364	full name	openid-connect	oidc-full-name-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
30a111b9-67c1-40b7-9ba7-81179eab9047	family name	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
3466a8ed-9741-471e-89d7-529909f2b3ba	given name	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	middle name	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
e1bc53c6-85d3-42ff-806d-c2499f2b5758	nickname	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
980e92fd-513b-428e-9a38-004df4f1f777	username	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
5e9faa33-204b-4520-b794-05144de5514e	profile	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	picture	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
f6083e64-2f6a-42ff-8212-c2577810595c	website	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
3c4251db-1971-4301-a695-2576aaa1f918	gender	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	birthdate	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
438d82a2-bdb0-441e-987c-643478582d37	zoneinfo	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
10154089-bcfc-4d64-b6eb-2f7a5853db79	locale	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	updated at	openid-connect	oidc-usermodel-attribute-mapper	\N	77258524-6f0f-4406-b315-7ddc4796c00d
4924c400-3cd0-4995-ab2f-784a5851fe0a	email	openid-connect	oidc-usermodel-attribute-mapper	\N	653a25e7-40d9-4b92-a25e-bb8455b6ebdf
72474281-674f-4a61-92b2-086400b404b8	email verified	openid-connect	oidc-usermodel-property-mapper	\N	653a25e7-40d9-4b92-a25e-bb8455b6ebdf
c58d2098-23ae-4565-9404-19a3f2c9b511	address	openid-connect	oidc-address-mapper	\N	40d8effa-ea43-4033-a14c-357a47b72d7c
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	phone number	openid-connect	oidc-usermodel-attribute-mapper	\N	d8c9cf61-7cc8-4290-89b2-ab17995ff99d
e70b12c3-4258-44f5-9cfe-8324a23ed245	phone number verified	openid-connect	oidc-usermodel-attribute-mapper	\N	d8c9cf61-7cc8-4290-89b2-ab17995ff99d
44912f45-b7d8-403e-b6de-beb157c48603	realm roles	openid-connect	oidc-usermodel-realm-role-mapper	\N	086a4221-efa4-40b1-9f46-97e5d68fdf20
a13e8b51-1fc3-4379-9523-fd841f88948e	client roles	openid-connect	oidc-usermodel-client-role-mapper	\N	086a4221-efa4-40b1-9f46-97e5d68fdf20
a32e0825-9d06-474c-9ed6-d4f660e64e31	audience resolve	openid-connect	oidc-audience-resolve-mapper	\N	086a4221-efa4-40b1-9f46-97e5d68fdf20
f1934899-4454-405e-9b99-4ca0094343c8	allowed web origins	openid-connect	oidc-allowed-origins-mapper	\N	61816b49-1207-4d27-852b-b14874c5eddf
426fa176-33b3-4948-a32d-2aa929444ccb	upn	openid-connect	oidc-usermodel-attribute-mapper	\N	84a15d18-e232-4be0-86ea-3458c0dab9b3
2277ec1e-e273-49b1-a951-3b920ca55e6c	groups	openid-connect	oidc-usermodel-realm-role-mapper	\N	84a15d18-e232-4be0-86ea-3458c0dab9b3
423b09a9-3b22-4dc9-b915-21f094ad00b8	acr loa level	openid-connect	oidc-acr-mapper	\N	a8cefe79-91a3-45ea-b561-5aff65223896
086c33e9-f9b8-44c2-a811-2698c901cc49	auth_time	openid-connect	oidc-usersessionmodel-note-mapper	\N	30aca326-0e4f-4226-bfa0-a7c546848c95
8f168006-5dde-45c1-8199-ecd8a708ca6d	sub	openid-connect	oidc-sub-mapper	\N	30aca326-0e4f-4226-bfa0-a7c546848c95
ef802997-5b20-4430-9790-752b5c4509f0	Client ID	openid-connect	oidc-usersessionmodel-note-mapper	\N	7cf38aa1-6d16-4883-bd8b-84126e385179
08d6eef5-fd50-4667-a381-ada6a1d417e0	Client Host	openid-connect	oidc-usersessionmodel-note-mapper	\N	7cf38aa1-6d16-4883-bd8b-84126e385179
04dc9e96-0b8b-488b-b91a-b2c04ec6eca7	Client IP Address	openid-connect	oidc-usersessionmodel-note-mapper	\N	7cf38aa1-6d16-4883-bd8b-84126e385179
130a4061-8d25-4dbb-9f4a-1217ebfb05c3	organization	openid-connect	oidc-organization-membership-mapper	\N	d3507a8a-46c0-4ae7-9011-fc52c5207e07
38ed1bab-30e2-4962-b909-d8c9a1c37379	allowed web origins	openid-connect	oidc-allowed-origins-mapper	\N	38b9f19b-48c5-49f2-a73f-07a8404f2c48
b19e834e-8d45-4714-9b4d-86927380e401	role list	saml	saml-role-list-mapper	\N	67bc1745-9981-4d04-88a8-871d88a7e522
e1979a48-4e46-4499-a4bc-e54696b9fcd7	phone number	openid-connect	oidc-usermodel-attribute-mapper	\N	5b61aded-f5c8-4ad3-b779-065520195daa
f9322827-a913-418b-a033-85bc1b67553d	phone number verified	openid-connect	oidc-usermodel-attribute-mapper	\N	5b61aded-f5c8-4ad3-b779-065520195daa
5f4363eb-6f79-4d93-b1d7-5fd019515707	address	openid-connect	oidc-address-mapper	\N	364cdea3-6979-46a0-85f1-222797349de4
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	organization	openid-connect	oidc-organization-membership-mapper	\N	54b31ac9-dea0-43d0-aa3a-1f691b495492
4cd3f17c-82ca-4928-8b89-f9856b9f8baa	organization	saml	saml-organization-membership-mapper	\N	df6a0a58-c6a8-4534-83b1-7b52b3aa62f9
07e08a9e-c672-4009-a81e-90dd9811f24b	realm roles	openid-connect	oidc-usermodel-realm-role-mapper	\N	147f68f2-1deb-489e-90c1-1f0a216aca17
d17c98bc-fe30-4eac-ac57-d6c28df6f079	audience resolve	openid-connect	oidc-audience-resolve-mapper	\N	147f68f2-1deb-489e-90c1-1f0a216aca17
442b0e72-3a52-4eeb-a97a-1832495579eb	client roles	openid-connect	oidc-usermodel-client-role-mapper	\N	147f68f2-1deb-489e-90c1-1f0a216aca17
32c558eb-74ea-4b24-a3e8-dee99243d874	sub	openid-connect	oidc-sub-mapper	\N	c87139e6-dacf-4a3b-ab0e-c74899e16e31
9a400935-8116-4278-a005-d3d26f479318	auth_time	openid-connect	oidc-usersessionmodel-note-mapper	\N	c87139e6-dacf-4a3b-ab0e-c74899e16e31
d2264d9a-a274-43a3-8732-a07db630d4bb	upn	openid-connect	oidc-usermodel-attribute-mapper	\N	3f34b32f-25ee-4770-979c-918b005c06c6
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	groups	openid-connect	oidc-usermodel-realm-role-mapper	\N	3f34b32f-25ee-4770-979c-918b005c06c6
9d04f703-4654-44c6-bbed-9ac5d471e7a9	acr loa level	openid-connect	oidc-acr-mapper	\N	2f4c6846-d426-4d40-a15f-1acd7351a946
0e879dc3-8589-4d39-8fda-4397fa15f558	gender	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
6525efc2-6890-449d-8780-b7ef51f353c5	website	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	username	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
f287c45c-25ca-41ae-9646-b993bc556f83	locale	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
eaa00e9d-b373-41bb-93b8-9612538ef323	updated at	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
50c6f93b-64a7-4536-aca0-5ea706e96d73	middle name	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
157edb14-92b3-4d53-b167-edcb022878ed	birthdate	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	zoneinfo	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
8c0244d2-a54c-4f7a-8fc2-76d51325f739	full name	openid-connect	oidc-full-name-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	picture	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	profile	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
b220d67b-999b-461e-9d70-12e0fd92bd1f	nickname	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
6b523c3e-d55b-4b11-8068-754c16ac7b13	family name	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
b3e280cd-87c5-4250-8df7-f1402f506d35	given name	openid-connect	oidc-usermodel-attribute-mapper	\N	fd772a4e-cf4e-4c53-b03c-9a07ffa7ca26
c597a77b-9566-40e6-a747-27141a1d9fc9	email	openid-connect	oidc-usermodel-attribute-mapper	\N	1d2bd933-a550-4d11-aa78-258954290a9c
2efe040e-087d-452e-8ba3-74473577a516	email verified	openid-connect	oidc-usermodel-property-mapper	\N	1d2bd933-a550-4d11-aa78-258954290a9c
7632e424-6a7c-45af-ab6f-a6d0a55d9989	audience resolve	openid-connect	oidc-audience-resolve-mapper	157e8078-530f-467a-9072-46f2ea6627fb	\N
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	Client IP Address	openid-connect	oidc-usersessionmodel-note-mapper	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
2c726957-b7b0-45ae-8329-8cb222c07362	Client Host	openid-connect	oidc-usersessionmodel-note-mapper	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
15565545-1b18-40e4-97c1-893ff8c247ef	Client ID	openid-connect	oidc-usersessionmodel-note-mapper	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
75c76d36-2446-4eb7-bd71-3ff0884fd060	locale	openid-connect	oidc-usermodel-attribute-mapper	60c887d6-2ce7-4fe9-98f0-fe2625266194	\N
47af43ea-4a08-40f5-8ec1-3fc940e8ab69	Client ID	openid-connect	oidc-usersessionmodel-note-mapper	\N	9737a927-f817-4a2b-849f-e86ee0537138
9222a270-418e-40cb-b879-a2c509117786	Client Host	openid-connect	oidc-usersessionmodel-note-mapper	\N	9737a927-f817-4a2b-849f-e86ee0537138
58a22041-39ec-49fd-80d6-9724f6fa7e9f	Client IP Address	openid-connect	oidc-usersessionmodel-note-mapper	\N	9737a927-f817-4a2b-849f-e86ee0537138
\.


--
-- Data for Name: protocol_mapper_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.protocol_mapper_config (protocol_mapper_id, value, name) FROM stdin;
ab9f0dbc-2285-4961-9d8c-024289a9b481	true	introspection.token.claim
ab9f0dbc-2285-4961-9d8c-024289a9b481	true	userinfo.token.claim
ab9f0dbc-2285-4961-9d8c-024289a9b481	locale	user.attribute
ab9f0dbc-2285-4961-9d8c-024289a9b481	true	id.token.claim
ab9f0dbc-2285-4961-9d8c-024289a9b481	true	access.token.claim
ab9f0dbc-2285-4961-9d8c-024289a9b481	locale	claim.name
ab9f0dbc-2285-4961-9d8c-024289a9b481	String	jsonType.label
b89eb0f1-36b9-4557-80bf-f587ad10b7af	false	single
b89eb0f1-36b9-4557-80bf-f587ad10b7af	Basic	attribute.nameformat
b89eb0f1-36b9-4557-80bf-f587ad10b7af	Role	attribute.name
10154089-bcfc-4d64-b6eb-2f7a5853db79	true	introspection.token.claim
10154089-bcfc-4d64-b6eb-2f7a5853db79	true	userinfo.token.claim
10154089-bcfc-4d64-b6eb-2f7a5853db79	locale	user.attribute
10154089-bcfc-4d64-b6eb-2f7a5853db79	true	id.token.claim
10154089-bcfc-4d64-b6eb-2f7a5853db79	true	access.token.claim
10154089-bcfc-4d64-b6eb-2f7a5853db79	locale	claim.name
10154089-bcfc-4d64-b6eb-2f7a5853db79	String	jsonType.label
30a111b9-67c1-40b7-9ba7-81179eab9047	true	introspection.token.claim
30a111b9-67c1-40b7-9ba7-81179eab9047	true	userinfo.token.claim
30a111b9-67c1-40b7-9ba7-81179eab9047	lastName	user.attribute
30a111b9-67c1-40b7-9ba7-81179eab9047	true	id.token.claim
30a111b9-67c1-40b7-9ba7-81179eab9047	true	access.token.claim
30a111b9-67c1-40b7-9ba7-81179eab9047	family_name	claim.name
30a111b9-67c1-40b7-9ba7-81179eab9047	String	jsonType.label
3466a8ed-9741-471e-89d7-529909f2b3ba	true	introspection.token.claim
3466a8ed-9741-471e-89d7-529909f2b3ba	true	userinfo.token.claim
3466a8ed-9741-471e-89d7-529909f2b3ba	firstName	user.attribute
3466a8ed-9741-471e-89d7-529909f2b3ba	true	id.token.claim
3466a8ed-9741-471e-89d7-529909f2b3ba	true	access.token.claim
3466a8ed-9741-471e-89d7-529909f2b3ba	given_name	claim.name
3466a8ed-9741-471e-89d7-529909f2b3ba	String	jsonType.label
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	true	introspection.token.claim
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	true	userinfo.token.claim
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	picture	user.attribute
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	true	id.token.claim
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	true	access.token.claim
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	picture	claim.name
39ba79c8-39fd-4f62-a687-6f6be30bb2ac	String	jsonType.label
3c4251db-1971-4301-a695-2576aaa1f918	true	introspection.token.claim
3c4251db-1971-4301-a695-2576aaa1f918	true	userinfo.token.claim
3c4251db-1971-4301-a695-2576aaa1f918	gender	user.attribute
3c4251db-1971-4301-a695-2576aaa1f918	true	id.token.claim
3c4251db-1971-4301-a695-2576aaa1f918	true	access.token.claim
3c4251db-1971-4301-a695-2576aaa1f918	gender	claim.name
3c4251db-1971-4301-a695-2576aaa1f918	String	jsonType.label
438d82a2-bdb0-441e-987c-643478582d37	true	introspection.token.claim
438d82a2-bdb0-441e-987c-643478582d37	true	userinfo.token.claim
438d82a2-bdb0-441e-987c-643478582d37	zoneinfo	user.attribute
438d82a2-bdb0-441e-987c-643478582d37	true	id.token.claim
438d82a2-bdb0-441e-987c-643478582d37	true	access.token.claim
438d82a2-bdb0-441e-987c-643478582d37	zoneinfo	claim.name
438d82a2-bdb0-441e-987c-643478582d37	String	jsonType.label
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	true	introspection.token.claim
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	true	userinfo.token.claim
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	middleName	user.attribute
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	true	id.token.claim
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	true	access.token.claim
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	middle_name	claim.name
5c60d8ba-1f5e-40b6-859e-e3b9fae95a64	String	jsonType.label
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	true	introspection.token.claim
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	true	userinfo.token.claim
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	birthdate	user.attribute
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	true	id.token.claim
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	true	access.token.claim
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	birthdate	claim.name
5e98f73e-b109-45d0-9e02-5e0cffccf3b1	String	jsonType.label
5e9faa33-204b-4520-b794-05144de5514e	true	introspection.token.claim
5e9faa33-204b-4520-b794-05144de5514e	true	userinfo.token.claim
5e9faa33-204b-4520-b794-05144de5514e	profile	user.attribute
5e9faa33-204b-4520-b794-05144de5514e	true	id.token.claim
5e9faa33-204b-4520-b794-05144de5514e	true	access.token.claim
5e9faa33-204b-4520-b794-05144de5514e	profile	claim.name
5e9faa33-204b-4520-b794-05144de5514e	String	jsonType.label
838e6a17-92b5-46ae-a2f6-ebcbfce2b364	true	introspection.token.claim
838e6a17-92b5-46ae-a2f6-ebcbfce2b364	true	userinfo.token.claim
838e6a17-92b5-46ae-a2f6-ebcbfce2b364	true	id.token.claim
838e6a17-92b5-46ae-a2f6-ebcbfce2b364	true	access.token.claim
980e92fd-513b-428e-9a38-004df4f1f777	true	introspection.token.claim
980e92fd-513b-428e-9a38-004df4f1f777	true	userinfo.token.claim
980e92fd-513b-428e-9a38-004df4f1f777	username	user.attribute
980e92fd-513b-428e-9a38-004df4f1f777	true	id.token.claim
980e92fd-513b-428e-9a38-004df4f1f777	true	access.token.claim
980e92fd-513b-428e-9a38-004df4f1f777	preferred_username	claim.name
980e92fd-513b-428e-9a38-004df4f1f777	String	jsonType.label
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	true	introspection.token.claim
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	true	userinfo.token.claim
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	updatedAt	user.attribute
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	true	id.token.claim
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	true	access.token.claim
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	updated_at	claim.name
da5324ea-d5e4-4e86-9ba4-c1683673f5ae	long	jsonType.label
e1bc53c6-85d3-42ff-806d-c2499f2b5758	true	introspection.token.claim
e1bc53c6-85d3-42ff-806d-c2499f2b5758	true	userinfo.token.claim
e1bc53c6-85d3-42ff-806d-c2499f2b5758	nickname	user.attribute
e1bc53c6-85d3-42ff-806d-c2499f2b5758	true	id.token.claim
e1bc53c6-85d3-42ff-806d-c2499f2b5758	true	access.token.claim
e1bc53c6-85d3-42ff-806d-c2499f2b5758	nickname	claim.name
e1bc53c6-85d3-42ff-806d-c2499f2b5758	String	jsonType.label
f6083e64-2f6a-42ff-8212-c2577810595c	true	introspection.token.claim
f6083e64-2f6a-42ff-8212-c2577810595c	true	userinfo.token.claim
f6083e64-2f6a-42ff-8212-c2577810595c	website	user.attribute
f6083e64-2f6a-42ff-8212-c2577810595c	true	id.token.claim
f6083e64-2f6a-42ff-8212-c2577810595c	true	access.token.claim
f6083e64-2f6a-42ff-8212-c2577810595c	website	claim.name
f6083e64-2f6a-42ff-8212-c2577810595c	String	jsonType.label
4924c400-3cd0-4995-ab2f-784a5851fe0a	true	introspection.token.claim
4924c400-3cd0-4995-ab2f-784a5851fe0a	true	userinfo.token.claim
4924c400-3cd0-4995-ab2f-784a5851fe0a	email	user.attribute
4924c400-3cd0-4995-ab2f-784a5851fe0a	true	id.token.claim
4924c400-3cd0-4995-ab2f-784a5851fe0a	true	access.token.claim
4924c400-3cd0-4995-ab2f-784a5851fe0a	email	claim.name
4924c400-3cd0-4995-ab2f-784a5851fe0a	String	jsonType.label
72474281-674f-4a61-92b2-086400b404b8	true	introspection.token.claim
72474281-674f-4a61-92b2-086400b404b8	true	userinfo.token.claim
72474281-674f-4a61-92b2-086400b404b8	emailVerified	user.attribute
72474281-674f-4a61-92b2-086400b404b8	true	id.token.claim
72474281-674f-4a61-92b2-086400b404b8	true	access.token.claim
72474281-674f-4a61-92b2-086400b404b8	email_verified	claim.name
72474281-674f-4a61-92b2-086400b404b8	boolean	jsonType.label
c58d2098-23ae-4565-9404-19a3f2c9b511	formatted	user.attribute.formatted
c58d2098-23ae-4565-9404-19a3f2c9b511	country	user.attribute.country
c58d2098-23ae-4565-9404-19a3f2c9b511	true	introspection.token.claim
c58d2098-23ae-4565-9404-19a3f2c9b511	postal_code	user.attribute.postal_code
c58d2098-23ae-4565-9404-19a3f2c9b511	true	userinfo.token.claim
c58d2098-23ae-4565-9404-19a3f2c9b511	street	user.attribute.street
c58d2098-23ae-4565-9404-19a3f2c9b511	true	id.token.claim
c58d2098-23ae-4565-9404-19a3f2c9b511	region	user.attribute.region
c58d2098-23ae-4565-9404-19a3f2c9b511	true	access.token.claim
c58d2098-23ae-4565-9404-19a3f2c9b511	locality	user.attribute.locality
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	true	introspection.token.claim
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	true	userinfo.token.claim
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	phoneNumber	user.attribute
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	true	id.token.claim
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	true	access.token.claim
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	phone_number	claim.name
d5e01339-b3bd-4ea6-bbcd-ac9f11a113ed	String	jsonType.label
e70b12c3-4258-44f5-9cfe-8324a23ed245	true	introspection.token.claim
e70b12c3-4258-44f5-9cfe-8324a23ed245	true	userinfo.token.claim
e70b12c3-4258-44f5-9cfe-8324a23ed245	phoneNumberVerified	user.attribute
e70b12c3-4258-44f5-9cfe-8324a23ed245	true	id.token.claim
e70b12c3-4258-44f5-9cfe-8324a23ed245	true	access.token.claim
e70b12c3-4258-44f5-9cfe-8324a23ed245	phone_number_verified	claim.name
e70b12c3-4258-44f5-9cfe-8324a23ed245	boolean	jsonType.label
44912f45-b7d8-403e-b6de-beb157c48603	true	introspection.token.claim
44912f45-b7d8-403e-b6de-beb157c48603	true	multivalued
44912f45-b7d8-403e-b6de-beb157c48603	foo	user.attribute
44912f45-b7d8-403e-b6de-beb157c48603	true	access.token.claim
44912f45-b7d8-403e-b6de-beb157c48603	realm_access.roles	claim.name
44912f45-b7d8-403e-b6de-beb157c48603	String	jsonType.label
a13e8b51-1fc3-4379-9523-fd841f88948e	true	introspection.token.claim
a13e8b51-1fc3-4379-9523-fd841f88948e	true	multivalued
a13e8b51-1fc3-4379-9523-fd841f88948e	foo	user.attribute
a13e8b51-1fc3-4379-9523-fd841f88948e	true	access.token.claim
a13e8b51-1fc3-4379-9523-fd841f88948e	resource_access.${client_id}.roles	claim.name
a13e8b51-1fc3-4379-9523-fd841f88948e	String	jsonType.label
a32e0825-9d06-474c-9ed6-d4f660e64e31	true	introspection.token.claim
a32e0825-9d06-474c-9ed6-d4f660e64e31	true	access.token.claim
f1934899-4454-405e-9b99-4ca0094343c8	true	introspection.token.claim
f1934899-4454-405e-9b99-4ca0094343c8	true	access.token.claim
2277ec1e-e273-49b1-a951-3b920ca55e6c	true	introspection.token.claim
2277ec1e-e273-49b1-a951-3b920ca55e6c	true	multivalued
2277ec1e-e273-49b1-a951-3b920ca55e6c	foo	user.attribute
2277ec1e-e273-49b1-a951-3b920ca55e6c	true	id.token.claim
2277ec1e-e273-49b1-a951-3b920ca55e6c	true	access.token.claim
2277ec1e-e273-49b1-a951-3b920ca55e6c	groups	claim.name
2277ec1e-e273-49b1-a951-3b920ca55e6c	String	jsonType.label
426fa176-33b3-4948-a32d-2aa929444ccb	true	introspection.token.claim
426fa176-33b3-4948-a32d-2aa929444ccb	true	userinfo.token.claim
426fa176-33b3-4948-a32d-2aa929444ccb	username	user.attribute
426fa176-33b3-4948-a32d-2aa929444ccb	true	id.token.claim
426fa176-33b3-4948-a32d-2aa929444ccb	true	access.token.claim
426fa176-33b3-4948-a32d-2aa929444ccb	upn	claim.name
426fa176-33b3-4948-a32d-2aa929444ccb	String	jsonType.label
423b09a9-3b22-4dc9-b915-21f094ad00b8	true	introspection.token.claim
423b09a9-3b22-4dc9-b915-21f094ad00b8	true	id.token.claim
423b09a9-3b22-4dc9-b915-21f094ad00b8	true	access.token.claim
086c33e9-f9b8-44c2-a811-2698c901cc49	AUTH_TIME	user.session.note
086c33e9-f9b8-44c2-a811-2698c901cc49	true	introspection.token.claim
086c33e9-f9b8-44c2-a811-2698c901cc49	true	id.token.claim
086c33e9-f9b8-44c2-a811-2698c901cc49	true	access.token.claim
086c33e9-f9b8-44c2-a811-2698c901cc49	auth_time	claim.name
086c33e9-f9b8-44c2-a811-2698c901cc49	long	jsonType.label
8f168006-5dde-45c1-8199-ecd8a708ca6d	true	introspection.token.claim
8f168006-5dde-45c1-8199-ecd8a708ca6d	true	access.token.claim
04dc9e96-0b8b-488b-b91a-b2c04ec6eca7	clientAddress	user.session.note
04dc9e96-0b8b-488b-b91a-b2c04ec6eca7	true	introspection.token.claim
04dc9e96-0b8b-488b-b91a-b2c04ec6eca7	true	id.token.claim
04dc9e96-0b8b-488b-b91a-b2c04ec6eca7	true	access.token.claim
04dc9e96-0b8b-488b-b91a-b2c04ec6eca7	clientAddress	claim.name
04dc9e96-0b8b-488b-b91a-b2c04ec6eca7	String	jsonType.label
08d6eef5-fd50-4667-a381-ada6a1d417e0	clientHost	user.session.note
08d6eef5-fd50-4667-a381-ada6a1d417e0	true	introspection.token.claim
08d6eef5-fd50-4667-a381-ada6a1d417e0	true	id.token.claim
08d6eef5-fd50-4667-a381-ada6a1d417e0	true	access.token.claim
08d6eef5-fd50-4667-a381-ada6a1d417e0	clientHost	claim.name
08d6eef5-fd50-4667-a381-ada6a1d417e0	String	jsonType.label
ef802997-5b20-4430-9790-752b5c4509f0	client_id	user.session.note
ef802997-5b20-4430-9790-752b5c4509f0	true	introspection.token.claim
ef802997-5b20-4430-9790-752b5c4509f0	true	id.token.claim
ef802997-5b20-4430-9790-752b5c4509f0	true	access.token.claim
ef802997-5b20-4430-9790-752b5c4509f0	client_id	claim.name
ef802997-5b20-4430-9790-752b5c4509f0	String	jsonType.label
130a4061-8d25-4dbb-9f4a-1217ebfb05c3	true	introspection.token.claim
130a4061-8d25-4dbb-9f4a-1217ebfb05c3	true	multivalued
130a4061-8d25-4dbb-9f4a-1217ebfb05c3	true	id.token.claim
130a4061-8d25-4dbb-9f4a-1217ebfb05c3	true	access.token.claim
130a4061-8d25-4dbb-9f4a-1217ebfb05c3	organization	claim.name
130a4061-8d25-4dbb-9f4a-1217ebfb05c3	String	jsonType.label
38ed1bab-30e2-4962-b909-d8c9a1c37379	true	introspection.token.claim
38ed1bab-30e2-4962-b909-d8c9a1c37379	true	access.token.claim
b19e834e-8d45-4714-9b4d-86927380e401	false	single
b19e834e-8d45-4714-9b4d-86927380e401	Basic	attribute.nameformat
b19e834e-8d45-4714-9b4d-86927380e401	Role	attribute.name
e1979a48-4e46-4499-a4bc-e54696b9fcd7	true	introspection.token.claim
e1979a48-4e46-4499-a4bc-e54696b9fcd7	true	userinfo.token.claim
e1979a48-4e46-4499-a4bc-e54696b9fcd7	phoneNumber	user.attribute
e1979a48-4e46-4499-a4bc-e54696b9fcd7	true	id.token.claim
e1979a48-4e46-4499-a4bc-e54696b9fcd7	true	access.token.claim
e1979a48-4e46-4499-a4bc-e54696b9fcd7	phone_number	claim.name
e1979a48-4e46-4499-a4bc-e54696b9fcd7	String	jsonType.label
f9322827-a913-418b-a033-85bc1b67553d	true	introspection.token.claim
f9322827-a913-418b-a033-85bc1b67553d	true	userinfo.token.claim
f9322827-a913-418b-a033-85bc1b67553d	phoneNumberVerified	user.attribute
f9322827-a913-418b-a033-85bc1b67553d	true	id.token.claim
f9322827-a913-418b-a033-85bc1b67553d	true	access.token.claim
f9322827-a913-418b-a033-85bc1b67553d	phone_number_verified	claim.name
f9322827-a913-418b-a033-85bc1b67553d	boolean	jsonType.label
5f4363eb-6f79-4d93-b1d7-5fd019515707	formatted	user.attribute.formatted
5f4363eb-6f79-4d93-b1d7-5fd019515707	country	user.attribute.country
5f4363eb-6f79-4d93-b1d7-5fd019515707	true	introspection.token.claim
5f4363eb-6f79-4d93-b1d7-5fd019515707	postal_code	user.attribute.postal_code
5f4363eb-6f79-4d93-b1d7-5fd019515707	true	userinfo.token.claim
5f4363eb-6f79-4d93-b1d7-5fd019515707	street	user.attribute.street
5f4363eb-6f79-4d93-b1d7-5fd019515707	true	id.token.claim
5f4363eb-6f79-4d93-b1d7-5fd019515707	region	user.attribute.region
5f4363eb-6f79-4d93-b1d7-5fd019515707	true	access.token.claim
5f4363eb-6f79-4d93-b1d7-5fd019515707	locality	user.attribute.locality
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	true	introspection.token.claim
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	true	multivalued
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	true	userinfo.token.claim
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	true	id.token.claim
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	true	access.token.claim
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	organization	claim.name
bd9c9748-f8e7-4d2c-a7e0-fd00c6b6bbe6	String	jsonType.label
07e08a9e-c672-4009-a81e-90dd9811f24b	foo	user.attribute
07e08a9e-c672-4009-a81e-90dd9811f24b	true	introspection.token.claim
07e08a9e-c672-4009-a81e-90dd9811f24b	true	access.token.claim
07e08a9e-c672-4009-a81e-90dd9811f24b	realm_access.roles	claim.name
07e08a9e-c672-4009-a81e-90dd9811f24b	String	jsonType.label
07e08a9e-c672-4009-a81e-90dd9811f24b	true	multivalued
442b0e72-3a52-4eeb-a97a-1832495579eb	foo	user.attribute
442b0e72-3a52-4eeb-a97a-1832495579eb	true	introspection.token.claim
442b0e72-3a52-4eeb-a97a-1832495579eb	true	access.token.claim
442b0e72-3a52-4eeb-a97a-1832495579eb	resource_access.${client_id}.roles	claim.name
442b0e72-3a52-4eeb-a97a-1832495579eb	String	jsonType.label
442b0e72-3a52-4eeb-a97a-1832495579eb	true	multivalued
d17c98bc-fe30-4eac-ac57-d6c28df6f079	true	introspection.token.claim
d17c98bc-fe30-4eac-ac57-d6c28df6f079	true	access.token.claim
32c558eb-74ea-4b24-a3e8-dee99243d874	true	introspection.token.claim
32c558eb-74ea-4b24-a3e8-dee99243d874	true	access.token.claim
9a400935-8116-4278-a005-d3d26f479318	AUTH_TIME	user.session.note
9a400935-8116-4278-a005-d3d26f479318	true	introspection.token.claim
9a400935-8116-4278-a005-d3d26f479318	true	userinfo.token.claim
9a400935-8116-4278-a005-d3d26f479318	true	id.token.claim
9a400935-8116-4278-a005-d3d26f479318	true	access.token.claim
9a400935-8116-4278-a005-d3d26f479318	auth_time	claim.name
9a400935-8116-4278-a005-d3d26f479318	long	jsonType.label
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	true	introspection.token.claim
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	true	multivalued
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	true	userinfo.token.claim
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	foo	user.attribute
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	true	id.token.claim
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	true	access.token.claim
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	groups	claim.name
2b76f6d2-6b63-4bf1-9e97-87f3b686af50	String	jsonType.label
d2264d9a-a274-43a3-8732-a07db630d4bb	true	introspection.token.claim
d2264d9a-a274-43a3-8732-a07db630d4bb	true	userinfo.token.claim
d2264d9a-a274-43a3-8732-a07db630d4bb	username	user.attribute
d2264d9a-a274-43a3-8732-a07db630d4bb	true	id.token.claim
d2264d9a-a274-43a3-8732-a07db630d4bb	true	access.token.claim
d2264d9a-a274-43a3-8732-a07db630d4bb	upn	claim.name
d2264d9a-a274-43a3-8732-a07db630d4bb	String	jsonType.label
9d04f703-4654-44c6-bbed-9ac5d471e7a9	true	id.token.claim
9d04f703-4654-44c6-bbed-9ac5d471e7a9	true	introspection.token.claim
9d04f703-4654-44c6-bbed-9ac5d471e7a9	true	access.token.claim
9d04f703-4654-44c6-bbed-9ac5d471e7a9	true	userinfo.token.claim
0e879dc3-8589-4d39-8fda-4397fa15f558	true	introspection.token.claim
0e879dc3-8589-4d39-8fda-4397fa15f558	true	userinfo.token.claim
0e879dc3-8589-4d39-8fda-4397fa15f558	gender	user.attribute
0e879dc3-8589-4d39-8fda-4397fa15f558	true	id.token.claim
0e879dc3-8589-4d39-8fda-4397fa15f558	true	access.token.claim
0e879dc3-8589-4d39-8fda-4397fa15f558	gender	claim.name
0e879dc3-8589-4d39-8fda-4397fa15f558	String	jsonType.label
157edb14-92b3-4d53-b167-edcb022878ed	true	introspection.token.claim
157edb14-92b3-4d53-b167-edcb022878ed	true	userinfo.token.claim
157edb14-92b3-4d53-b167-edcb022878ed	birthdate	user.attribute
157edb14-92b3-4d53-b167-edcb022878ed	true	id.token.claim
157edb14-92b3-4d53-b167-edcb022878ed	true	access.token.claim
157edb14-92b3-4d53-b167-edcb022878ed	birthdate	claim.name
157edb14-92b3-4d53-b167-edcb022878ed	String	jsonType.label
50c6f93b-64a7-4536-aca0-5ea706e96d73	true	introspection.token.claim
50c6f93b-64a7-4536-aca0-5ea706e96d73	true	userinfo.token.claim
50c6f93b-64a7-4536-aca0-5ea706e96d73	middleName	user.attribute
50c6f93b-64a7-4536-aca0-5ea706e96d73	true	id.token.claim
50c6f93b-64a7-4536-aca0-5ea706e96d73	true	access.token.claim
50c6f93b-64a7-4536-aca0-5ea706e96d73	middle_name	claim.name
50c6f93b-64a7-4536-aca0-5ea706e96d73	String	jsonType.label
6525efc2-6890-449d-8780-b7ef51f353c5	true	introspection.token.claim
6525efc2-6890-449d-8780-b7ef51f353c5	true	userinfo.token.claim
6525efc2-6890-449d-8780-b7ef51f353c5	website	user.attribute
6525efc2-6890-449d-8780-b7ef51f353c5	true	id.token.claim
6525efc2-6890-449d-8780-b7ef51f353c5	true	access.token.claim
6525efc2-6890-449d-8780-b7ef51f353c5	website	claim.name
6525efc2-6890-449d-8780-b7ef51f353c5	String	jsonType.label
6b523c3e-d55b-4b11-8068-754c16ac7b13	true	introspection.token.claim
6b523c3e-d55b-4b11-8068-754c16ac7b13	true	userinfo.token.claim
6b523c3e-d55b-4b11-8068-754c16ac7b13	lastName	user.attribute
6b523c3e-d55b-4b11-8068-754c16ac7b13	true	id.token.claim
6b523c3e-d55b-4b11-8068-754c16ac7b13	true	access.token.claim
6b523c3e-d55b-4b11-8068-754c16ac7b13	family_name	claim.name
6b523c3e-d55b-4b11-8068-754c16ac7b13	String	jsonType.label
8c0244d2-a54c-4f7a-8fc2-76d51325f739	true	id.token.claim
8c0244d2-a54c-4f7a-8fc2-76d51325f739	true	introspection.token.claim
8c0244d2-a54c-4f7a-8fc2-76d51325f739	true	access.token.claim
8c0244d2-a54c-4f7a-8fc2-76d51325f739	true	userinfo.token.claim
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	true	introspection.token.claim
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	true	userinfo.token.claim
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	username	user.attribute
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	true	id.token.claim
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	true	access.token.claim
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	preferred_username	claim.name
90a79e24-8570-40c8-a5b0-016dc7e5c4a5	String	jsonType.label
b220d67b-999b-461e-9d70-12e0fd92bd1f	true	introspection.token.claim
b220d67b-999b-461e-9d70-12e0fd92bd1f	true	userinfo.token.claim
b220d67b-999b-461e-9d70-12e0fd92bd1f	nickname	user.attribute
b220d67b-999b-461e-9d70-12e0fd92bd1f	true	id.token.claim
b220d67b-999b-461e-9d70-12e0fd92bd1f	true	access.token.claim
b220d67b-999b-461e-9d70-12e0fd92bd1f	nickname	claim.name
b220d67b-999b-461e-9d70-12e0fd92bd1f	String	jsonType.label
b3e280cd-87c5-4250-8df7-f1402f506d35	true	introspection.token.claim
b3e280cd-87c5-4250-8df7-f1402f506d35	true	userinfo.token.claim
b3e280cd-87c5-4250-8df7-f1402f506d35	firstName	user.attribute
b3e280cd-87c5-4250-8df7-f1402f506d35	true	id.token.claim
b3e280cd-87c5-4250-8df7-f1402f506d35	true	access.token.claim
b3e280cd-87c5-4250-8df7-f1402f506d35	given_name	claim.name
b3e280cd-87c5-4250-8df7-f1402f506d35	String	jsonType.label
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	true	introspection.token.claim
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	true	userinfo.token.claim
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	zoneinfo	user.attribute
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	true	id.token.claim
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	true	access.token.claim
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	zoneinfo	claim.name
cacc8f90-a42e-4c0c-bdd6-1115c098bb3f	String	jsonType.label
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	true	introspection.token.claim
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	true	userinfo.token.claim
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	picture	user.attribute
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	true	id.token.claim
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	true	access.token.claim
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	picture	claim.name
e2f919c0-60ca-49ee-a7e4-34ccff0a6fea	String	jsonType.label
eaa00e9d-b373-41bb-93b8-9612538ef323	true	introspection.token.claim
eaa00e9d-b373-41bb-93b8-9612538ef323	true	userinfo.token.claim
eaa00e9d-b373-41bb-93b8-9612538ef323	updatedAt	user.attribute
eaa00e9d-b373-41bb-93b8-9612538ef323	true	id.token.claim
eaa00e9d-b373-41bb-93b8-9612538ef323	true	access.token.claim
eaa00e9d-b373-41bb-93b8-9612538ef323	updated_at	claim.name
eaa00e9d-b373-41bb-93b8-9612538ef323	long	jsonType.label
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	true	introspection.token.claim
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	true	userinfo.token.claim
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	profile	user.attribute
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	true	id.token.claim
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	true	access.token.claim
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	profile	claim.name
ec5c06ac-fd5f-49db-bdcd-32c7fd91f136	String	jsonType.label
f287c45c-25ca-41ae-9646-b993bc556f83	true	introspection.token.claim
f287c45c-25ca-41ae-9646-b993bc556f83	true	userinfo.token.claim
f287c45c-25ca-41ae-9646-b993bc556f83	locale	user.attribute
f287c45c-25ca-41ae-9646-b993bc556f83	true	id.token.claim
f287c45c-25ca-41ae-9646-b993bc556f83	true	access.token.claim
f287c45c-25ca-41ae-9646-b993bc556f83	locale	claim.name
f287c45c-25ca-41ae-9646-b993bc556f83	String	jsonType.label
2efe040e-087d-452e-8ba3-74473577a516	true	introspection.token.claim
2efe040e-087d-452e-8ba3-74473577a516	true	userinfo.token.claim
2efe040e-087d-452e-8ba3-74473577a516	emailVerified	user.attribute
2efe040e-087d-452e-8ba3-74473577a516	true	id.token.claim
2efe040e-087d-452e-8ba3-74473577a516	true	access.token.claim
2efe040e-087d-452e-8ba3-74473577a516	email_verified	claim.name
2efe040e-087d-452e-8ba3-74473577a516	boolean	jsonType.label
c597a77b-9566-40e6-a747-27141a1d9fc9	true	introspection.token.claim
c597a77b-9566-40e6-a747-27141a1d9fc9	true	userinfo.token.claim
c597a77b-9566-40e6-a747-27141a1d9fc9	email	user.attribute
c597a77b-9566-40e6-a747-27141a1d9fc9	true	id.token.claim
c597a77b-9566-40e6-a747-27141a1d9fc9	true	access.token.claim
c597a77b-9566-40e6-a747-27141a1d9fc9	email	claim.name
c597a77b-9566-40e6-a747-27141a1d9fc9	String	jsonType.label
15565545-1b18-40e4-97c1-893ff8c247ef	client_id	user.session.note
15565545-1b18-40e4-97c1-893ff8c247ef	true	introspection.token.claim
15565545-1b18-40e4-97c1-893ff8c247ef	true	userinfo.token.claim
15565545-1b18-40e4-97c1-893ff8c247ef	true	id.token.claim
15565545-1b18-40e4-97c1-893ff8c247ef	true	access.token.claim
15565545-1b18-40e4-97c1-893ff8c247ef	client_id	claim.name
15565545-1b18-40e4-97c1-893ff8c247ef	String	jsonType.label
2c726957-b7b0-45ae-8329-8cb222c07362	clientHost	user.session.note
2c726957-b7b0-45ae-8329-8cb222c07362	true	introspection.token.claim
2c726957-b7b0-45ae-8329-8cb222c07362	true	userinfo.token.claim
2c726957-b7b0-45ae-8329-8cb222c07362	true	id.token.claim
2c726957-b7b0-45ae-8329-8cb222c07362	true	access.token.claim
2c726957-b7b0-45ae-8329-8cb222c07362	clientHost	claim.name
2c726957-b7b0-45ae-8329-8cb222c07362	String	jsonType.label
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	clientAddress	user.session.note
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	true	introspection.token.claim
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	true	userinfo.token.claim
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	true	id.token.claim
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	true	access.token.claim
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	clientAddress	claim.name
ee52409a-cb2c-4379-9c5e-92a3ed3b935e	String	jsonType.label
75c76d36-2446-4eb7-bd71-3ff0884fd060	true	introspection.token.claim
75c76d36-2446-4eb7-bd71-3ff0884fd060	true	userinfo.token.claim
75c76d36-2446-4eb7-bd71-3ff0884fd060	locale	user.attribute
75c76d36-2446-4eb7-bd71-3ff0884fd060	true	id.token.claim
75c76d36-2446-4eb7-bd71-3ff0884fd060	true	access.token.claim
75c76d36-2446-4eb7-bd71-3ff0884fd060	locale	claim.name
75c76d36-2446-4eb7-bd71-3ff0884fd060	String	jsonType.label
47af43ea-4a08-40f5-8ec1-3fc940e8ab69	client_id	user.session.note
47af43ea-4a08-40f5-8ec1-3fc940e8ab69	true	introspection.token.claim
47af43ea-4a08-40f5-8ec1-3fc940e8ab69	true	id.token.claim
47af43ea-4a08-40f5-8ec1-3fc940e8ab69	true	access.token.claim
47af43ea-4a08-40f5-8ec1-3fc940e8ab69	client_id	claim.name
47af43ea-4a08-40f5-8ec1-3fc940e8ab69	String	jsonType.label
58a22041-39ec-49fd-80d6-9724f6fa7e9f	clientAddress	user.session.note
58a22041-39ec-49fd-80d6-9724f6fa7e9f	true	introspection.token.claim
58a22041-39ec-49fd-80d6-9724f6fa7e9f	true	id.token.claim
58a22041-39ec-49fd-80d6-9724f6fa7e9f	true	access.token.claim
58a22041-39ec-49fd-80d6-9724f6fa7e9f	clientAddress	claim.name
58a22041-39ec-49fd-80d6-9724f6fa7e9f	String	jsonType.label
9222a270-418e-40cb-b879-a2c509117786	clientHost	user.session.note
9222a270-418e-40cb-b879-a2c509117786	true	introspection.token.claim
9222a270-418e-40cb-b879-a2c509117786	true	id.token.claim
9222a270-418e-40cb-b879-a2c509117786	true	access.token.claim
9222a270-418e-40cb-b879-a2c509117786	clientHost	claim.name
9222a270-418e-40cb-b879-a2c509117786	String	jsonType.label
\.


--
-- Data for Name: realm; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm (id, access_code_lifespan, user_action_lifespan, access_token_lifespan, account_theme, admin_theme, email_theme, enabled, events_enabled, events_expiration, login_theme, name, not_before, password_policy, registration_allowed, remember_me, reset_password_allowed, social, ssl_required, sso_idle_timeout, sso_max_lifespan, update_profile_on_soc_login, verify_email, master_admin_client, login_lifespan, internationalization_enabled, default_locale, reg_email_as_username, admin_events_enabled, admin_events_details_enabled, edit_username_allowed, otp_policy_counter, otp_policy_window, otp_policy_period, otp_policy_digits, otp_policy_alg, otp_policy_type, browser_flow, registration_flow, direct_grant_flow, reset_credentials_flow, client_auth_flow, offline_session_idle_timeout, revoke_refresh_token, access_token_life_implicit, login_with_email_allowed, duplicate_emails_allowed, docker_auth_flow, refresh_token_max_reuse, allow_user_managed_access, sso_max_lifespan_remember_me, sso_idle_timeout_remember_me, default_role) FROM stdin;
955a00d0-1411-4e86-8ef2-bdedffd7a66f	60	300	60	\N	\N	\N	t	f	0	\N	master	0	\N	f	f	f	f	EXTERNAL	1800	36000	f	f	aeb1d986-2bef-405c-a65d-c190561c2f31	1800	f	\N	f	f	f	f	0	1	30	6	HmacSHA1	totp	88720b08-0957-4146-9ac9-60ffcb0cf8c0	20508aef-657a-438f-8d43-7246a41916bc	c142818d-e1c3-4984-bcd6-668e0e7b5c9a	52ecf8dd-e190-4618-b195-ad7ef4bac05e	a4982cc5-a485-4514-b1b9-cde6b785f8e3	2592000	f	900	t	f	bc147e2e-9c46-4f64-938c-5b0c54b8e2d2	0	f	0	0	74bbf2b8-0473-4e83-a487-af069f08b188
27d57df0-0794-4e96-92ac-85b802200864	60	300	300	\N	\N	\N	t	f	0	\N	FHIR-Auth	0	\N	f	f	f	f	EXTERNAL	1800	36000	f	f	1516ec14-8f75-485c-82c7-0df5c1d360d1	1800	f	\N	f	f	f	f	0	1	30	6	HmacSHA1	totp	11c1887b-aef0-4eb9-a262-e1222b430dcf	0ee368dd-05b2-44d8-9b53-f7c3dbc06dd8	e282ad24-f7b9-4537-a897-55ffae46f8a8	d3394390-d4bc-4df5-88ed-4f1665e4e780	08839456-c079-4f3d-8dd9-64e924cd83cd	2592000	f	900	t	f	10c92f67-3d8c-49c3-8f88-acebd3ca9d0c	0	f	0	0	39c3feae-b3f5-49b1-a6cf-1f91960d022d
\.


--
-- Data for Name: realm_attribute; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_attribute (name, realm_id, value) FROM stdin;
_browser_header.contentSecurityPolicyReportOnly	955a00d0-1411-4e86-8ef2-bdedffd7a66f	
_browser_header.xContentTypeOptions	955a00d0-1411-4e86-8ef2-bdedffd7a66f	nosniff
_browser_header.referrerPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	no-referrer
_browser_header.xRobotsTag	955a00d0-1411-4e86-8ef2-bdedffd7a66f	none
_browser_header.xFrameOptions	955a00d0-1411-4e86-8ef2-bdedffd7a66f	SAMEORIGIN
_browser_header.contentSecurityPolicy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	frame-src 'self'; frame-ancestors 'self'; object-src 'none';
_browser_header.strictTransportSecurity	955a00d0-1411-4e86-8ef2-bdedffd7a66f	max-age=31536000; includeSubDomains
bruteForceProtected	955a00d0-1411-4e86-8ef2-bdedffd7a66f	false
permanentLockout	955a00d0-1411-4e86-8ef2-bdedffd7a66f	false
maxTemporaryLockouts	955a00d0-1411-4e86-8ef2-bdedffd7a66f	0
bruteForceStrategy	955a00d0-1411-4e86-8ef2-bdedffd7a66f	MULTIPLE
maxFailureWaitSeconds	955a00d0-1411-4e86-8ef2-bdedffd7a66f	900
minimumQuickLoginWaitSeconds	955a00d0-1411-4e86-8ef2-bdedffd7a66f	60
waitIncrementSeconds	955a00d0-1411-4e86-8ef2-bdedffd7a66f	60
quickLoginCheckMilliSeconds	955a00d0-1411-4e86-8ef2-bdedffd7a66f	1000
maxDeltaTimeSeconds	955a00d0-1411-4e86-8ef2-bdedffd7a66f	43200
failureFactor	955a00d0-1411-4e86-8ef2-bdedffd7a66f	30
realmReusableOtpCode	955a00d0-1411-4e86-8ef2-bdedffd7a66f	false
firstBrokerLoginFlowId	955a00d0-1411-4e86-8ef2-bdedffd7a66f	c77a8f72-35a6-4abe-b855-546a1c7ec8f6
displayName	955a00d0-1411-4e86-8ef2-bdedffd7a66f	Keycloak
displayNameHtml	955a00d0-1411-4e86-8ef2-bdedffd7a66f	<div class="kc-logo-text"><span>Keycloak</span></div>
defaultSignatureAlgorithm	955a00d0-1411-4e86-8ef2-bdedffd7a66f	RS256
offlineSessionMaxLifespanEnabled	955a00d0-1411-4e86-8ef2-bdedffd7a66f	false
offlineSessionMaxLifespan	955a00d0-1411-4e86-8ef2-bdedffd7a66f	5184000
_browser_header.contentSecurityPolicyReportOnly	27d57df0-0794-4e96-92ac-85b802200864	
_browser_header.xContentTypeOptions	27d57df0-0794-4e96-92ac-85b802200864	nosniff
_browser_header.referrerPolicy	27d57df0-0794-4e96-92ac-85b802200864	no-referrer
_browser_header.xRobotsTag	27d57df0-0794-4e96-92ac-85b802200864	none
_browser_header.xFrameOptions	27d57df0-0794-4e96-92ac-85b802200864	SAMEORIGIN
_browser_header.contentSecurityPolicy	27d57df0-0794-4e96-92ac-85b802200864	frame-src 'self'; frame-ancestors 'self'; object-src 'none';
_browser_header.strictTransportSecurity	27d57df0-0794-4e96-92ac-85b802200864	max-age=31536000; includeSubDomains
bruteForceProtected	27d57df0-0794-4e96-92ac-85b802200864	false
permanentLockout	27d57df0-0794-4e96-92ac-85b802200864	false
maxTemporaryLockouts	27d57df0-0794-4e96-92ac-85b802200864	0
bruteForceStrategy	27d57df0-0794-4e96-92ac-85b802200864	MULTIPLE
maxFailureWaitSeconds	27d57df0-0794-4e96-92ac-85b802200864	900
minimumQuickLoginWaitSeconds	27d57df0-0794-4e96-92ac-85b802200864	60
waitIncrementSeconds	27d57df0-0794-4e96-92ac-85b802200864	60
quickLoginCheckMilliSeconds	27d57df0-0794-4e96-92ac-85b802200864	1000
maxDeltaTimeSeconds	27d57df0-0794-4e96-92ac-85b802200864	43200
failureFactor	27d57df0-0794-4e96-92ac-85b802200864	30
realmReusableOtpCode	27d57df0-0794-4e96-92ac-85b802200864	false
defaultSignatureAlgorithm	27d57df0-0794-4e96-92ac-85b802200864	RS256
offlineSessionMaxLifespanEnabled	27d57df0-0794-4e96-92ac-85b802200864	false
offlineSessionMaxLifespan	27d57df0-0794-4e96-92ac-85b802200864	5184000
clientSessionIdleTimeout	27d57df0-0794-4e96-92ac-85b802200864	0
clientSessionMaxLifespan	27d57df0-0794-4e96-92ac-85b802200864	0
clientOfflineSessionIdleTimeout	27d57df0-0794-4e96-92ac-85b802200864	0
clientOfflineSessionMaxLifespan	27d57df0-0794-4e96-92ac-85b802200864	0
actionTokenGeneratedByAdminLifespan	27d57df0-0794-4e96-92ac-85b802200864	43200
actionTokenGeneratedByUserLifespan	27d57df0-0794-4e96-92ac-85b802200864	300
oauth2DeviceCodeLifespan	27d57df0-0794-4e96-92ac-85b802200864	600
oauth2DevicePollingInterval	27d57df0-0794-4e96-92ac-85b802200864	5
organizationsEnabled	27d57df0-0794-4e96-92ac-85b802200864	false
webAuthnPolicyRpEntityName	27d57df0-0794-4e96-92ac-85b802200864	keycloak
webAuthnPolicySignatureAlgorithms	27d57df0-0794-4e96-92ac-85b802200864	ES256,RS256
webAuthnPolicyRpId	27d57df0-0794-4e96-92ac-85b802200864	
webAuthnPolicyAttestationConveyancePreference	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyAuthenticatorAttachment	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyRequireResidentKey	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyUserVerificationRequirement	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyCreateTimeout	27d57df0-0794-4e96-92ac-85b802200864	0
webAuthnPolicyAvoidSameAuthenticatorRegister	27d57df0-0794-4e96-92ac-85b802200864	false
webAuthnPolicyRpEntityNamePasswordless	27d57df0-0794-4e96-92ac-85b802200864	keycloak
webAuthnPolicySignatureAlgorithmsPasswordless	27d57df0-0794-4e96-92ac-85b802200864	ES256,RS256
webAuthnPolicyRpIdPasswordless	27d57df0-0794-4e96-92ac-85b802200864	
webAuthnPolicyAttestationConveyancePreferencePasswordless	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyAuthenticatorAttachmentPasswordless	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyRequireResidentKeyPasswordless	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyUserVerificationRequirementPasswordless	27d57df0-0794-4e96-92ac-85b802200864	not specified
webAuthnPolicyCreateTimeoutPasswordless	27d57df0-0794-4e96-92ac-85b802200864	0
webAuthnPolicyAvoidSameAuthenticatorRegisterPasswordless	27d57df0-0794-4e96-92ac-85b802200864	false
cibaBackchannelTokenDeliveryMode	27d57df0-0794-4e96-92ac-85b802200864	poll
cibaExpiresIn	27d57df0-0794-4e96-92ac-85b802200864	120
cibaInterval	27d57df0-0794-4e96-92ac-85b802200864	5
cibaAuthRequestedUserHint	27d57df0-0794-4e96-92ac-85b802200864	login_hint
parRequestUriLifespan	27d57df0-0794-4e96-92ac-85b802200864	60
firstBrokerLoginFlowId	27d57df0-0794-4e96-92ac-85b802200864	b90b5d9b-cbdc-4b9f-b90d-881cf34c943d
_browser_header.xXSSProtection	27d57df0-0794-4e96-92ac-85b802200864	1; mode=block
client-policies.profiles	27d57df0-0794-4e96-92ac-85b802200864	{"profiles":[]}
client-policies.policies	27d57df0-0794-4e96-92ac-85b802200864	{"policies":[]}
\.


--
-- Data for Name: realm_default_groups; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_default_groups (realm_id, group_id) FROM stdin;
\.


--
-- Data for Name: realm_enabled_event_types; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_enabled_event_types (realm_id, value) FROM stdin;
\.


--
-- Data for Name: realm_events_listeners; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_events_listeners (realm_id, value) FROM stdin;
955a00d0-1411-4e86-8ef2-bdedffd7a66f	jboss-logging
27d57df0-0794-4e96-92ac-85b802200864	jboss-logging
\.


--
-- Data for Name: realm_localizations; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_localizations (realm_id, locale, texts) FROM stdin;
\.


--
-- Data for Name: realm_required_credential; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_required_credential (type, form_label, input, secret, realm_id) FROM stdin;
password	password	t	t	955a00d0-1411-4e86-8ef2-bdedffd7a66f
password	password	t	t	27d57df0-0794-4e96-92ac-85b802200864
\.


--
-- Data for Name: realm_smtp_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_smtp_config (realm_id, value, name) FROM stdin;
\.


--
-- Data for Name: realm_supported_locales; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.realm_supported_locales (realm_id, value) FROM stdin;
\.


--
-- Data for Name: redirect_uris; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.redirect_uris (client_id, value) FROM stdin;
0f0ec0f5-6e68-4308-8b92-25489a9feacf	/realms/master/account/*
acf59302-35a1-4e76-895c-f9a9c7234692	/realms/master/account/*
247c0e1e-e295-45ea-904d-824e58645759	/admin/master/console/*
c3acb65a-48ac-4cb0-8cc6-5b32421f94d6	/realms/FHIR-Auth/account/*
157e8078-530f-467a-9072-46f2ea6627fb	/realms/FHIR-Auth/account/*
f637d925-d634-4b92-ad79-fb1b387b3e2e	http://localhost:8080/*
60c887d6-2ce7-4fe9-98f0-fe2625266194	/admin/FHIR-Auth/console/*
\.


--
-- Data for Name: required_action_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.required_action_config (required_action_id, value, name) FROM stdin;
\.


--
-- Data for Name: required_action_provider; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.required_action_provider (id, alias, name, realm_id, enabled, default_action, provider_id, priority) FROM stdin;
ca5e981c-8f66-4123-afef-314693c30edc	VERIFY_EMAIL	Verify Email	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	VERIFY_EMAIL	50
afcd3f77-ad5a-4c8a-8384-2a9c035a315f	UPDATE_PROFILE	Update Profile	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	UPDATE_PROFILE	40
abf36f9a-a1fd-4676-a308-86a93cf051c0	CONFIGURE_TOTP	Configure OTP	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	CONFIGURE_TOTP	10
a97adb0a-9434-481b-bf50-9534cbf572a7	UPDATE_PASSWORD	Update Password	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	UPDATE_PASSWORD	30
56d56b44-c0f3-4f0b-ad5a-4b6dbc93c55b	TERMS_AND_CONDITIONS	Terms and Conditions	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	f	TERMS_AND_CONDITIONS	20
6fe4dc9a-27be-44c9-9614-cff3adbf930a	delete_account	Delete Account	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	f	delete_account	60
bd380010-6630-4486-a4b3-3f0e94fea6d1	delete_credential	Delete Credential	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	delete_credential	110
44feb0dd-b1d3-434b-9e41-e0e3006e7186	update_user_locale	Update User Locale	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	update_user_locale	1000
d9ad0469-74d1-4f28-a125-3d6d6e2dc8ff	UPDATE_EMAIL	Update Email	955a00d0-1411-4e86-8ef2-bdedffd7a66f	f	f	UPDATE_EMAIL	70
2579cd74-5730-4eaf-b27a-9d71bdb4c5be	CONFIGURE_RECOVERY_AUTHN_CODES	Recovery Authentication Codes	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	CONFIGURE_RECOVERY_AUTHN_CODES	130
df8121d4-731d-4f00-badb-ac17950085c5	webauthn-register	Webauthn Register	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	webauthn-register	80
1c891418-d857-4533-bc52-15ef4db7aa0b	webauthn-register-passwordless	Webauthn Register Passwordless	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	webauthn-register-passwordless	90
261e7e68-79ec-47bb-b9e5-be2f67454e74	VERIFY_PROFILE	Verify Profile	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	VERIFY_PROFILE	100
e9f58970-fd1e-4b54-87dc-5be547efa0fe	idp_link	Linking Identity Provider	955a00d0-1411-4e86-8ef2-bdedffd7a66f	t	f	idp_link	120
57e0636f-96cc-407b-a6c1-f2975e12a635	CONFIGURE_TOTP	Configure OTP	27d57df0-0794-4e96-92ac-85b802200864	t	f	CONFIGURE_TOTP	10
198c708c-de6a-4a36-ab20-732506b81417	TERMS_AND_CONDITIONS	Terms and Conditions	27d57df0-0794-4e96-92ac-85b802200864	f	f	TERMS_AND_CONDITIONS	20
72d075fd-d70d-4b1e-a6ab-e39b3be32c1e	UPDATE_PASSWORD	Update Password	27d57df0-0794-4e96-92ac-85b802200864	t	f	UPDATE_PASSWORD	30
c9d4512b-0972-4b73-9e98-e5be53ce12d4	UPDATE_PROFILE	Update Profile	27d57df0-0794-4e96-92ac-85b802200864	t	f	UPDATE_PROFILE	40
45ef54f3-68a4-4f8b-982a-feca245a7837	VERIFY_EMAIL	Verify Email	27d57df0-0794-4e96-92ac-85b802200864	t	f	VERIFY_EMAIL	50
9e0c5f2e-8002-4462-bbbc-1b6a6daaaf69	delete_account	Delete Account	27d57df0-0794-4e96-92ac-85b802200864	f	f	delete_account	60
caee1091-40ec-4f65-ad91-fed5a38987f0	webauthn-register	Webauthn Register	27d57df0-0794-4e96-92ac-85b802200864	t	f	webauthn-register	70
6b9b9c0a-171d-458c-a81f-2f3890cc55d8	webauthn-register-passwordless	Webauthn Register Passwordless	27d57df0-0794-4e96-92ac-85b802200864	t	f	webauthn-register-passwordless	80
4ce502e3-1dee-4f35-8aca-897f85762715	VERIFY_PROFILE	Verify Profile	27d57df0-0794-4e96-92ac-85b802200864	t	f	VERIFY_PROFILE	90
b1696041-6b51-4c8a-bee8-117ae272ee9f	delete_credential	Delete Credential	27d57df0-0794-4e96-92ac-85b802200864	t	f	delete_credential	100
0a538ce6-e2c2-4076-89e7-a318cc1be66b	update_user_locale	Update User Locale	27d57df0-0794-4e96-92ac-85b802200864	t	f	update_user_locale	1000
535212be-9b26-4afc-86e7-b75a1995964d	idp_link	Linking Identity Provider	27d57df0-0794-4e96-92ac-85b802200864	t	f	idp_link	120
\.


--
-- Data for Name: resource_attribute; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_attribute (id, name, value, resource_id) FROM stdin;
\.


--
-- Data for Name: resource_policy; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_policy (resource_id, policy_id) FROM stdin;
440f6acd-3eb0-45af-950f-419017359dda	efd93021-7e76-4202-ba03-d89330a48f66
440f6acd-3eb0-45af-950f-419017359dda	9661b3f8-a5f8-4e30-ac49-af00b078e62f
440f6acd-3eb0-45af-950f-419017359dda	18e46344-009c-4b0e-a943-c58960ee9871
440f6acd-3eb0-45af-950f-419017359dda	b9870a4c-1b3e-48d8-b633-b6d89910f1be
ea214052-69ff-4b40-989c-b6fe1b7087ed	5475198b-e4a2-40bc-8fa5-a9c9a87596f2
ea214052-69ff-4b40-989c-b6fe1b7087ed	21b596be-00a8-4d19-9456-f2cb1b6e5242
ea214052-69ff-4b40-989c-b6fe1b7087ed	6a039833-ded3-4195-9f18-e9fc6f9e31b2
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	adb786c1-c6c1-4db1-b4b1-607cab3085c7
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	fed1f1bf-3054-4aa9-985d-17487fb0e263
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	85594e45-be39-41e2-818a-75113a4d07b4
c62b165e-185c-473c-befc-0baf45c15538	494d18f3-70fa-49b5-8e0f-b40f3c5cd258
c62b165e-185c-473c-befc-0baf45c15538	35245166-481f-4bb9-9e7c-b31907128b21
c62b165e-185c-473c-befc-0baf45c15538	07d1240c-0b98-4b82-90fa-7ceb09fbd5da
df286129-a2e2-4c29-831a-8273b63b8158	d7af2a0a-2273-4768-b0c2-d85d8aca3011
1f4f2f17-eac0-4bd8-a049-5fe4f3da28e5	31044763-9265-48d2-a508-be0cd5430292
bed3163b-965a-41d3-84e7-82a425b6b75c	9a313617-6544-449e-a2aa-abb3eb9eb589
\.


--
-- Data for Name: resource_scope; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_scope (resource_id, scope_id) FROM stdin;
440f6acd-3eb0-45af-950f-419017359dda	d5c7f74b-98e2-4826-a36b-a14c398f96d8
440f6acd-3eb0-45af-950f-419017359dda	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
440f6acd-3eb0-45af-950f-419017359dda	24f29b23-290d-40b2-af73-0e40d69eebbf
440f6acd-3eb0-45af-950f-419017359dda	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
ea214052-69ff-4b40-989c-b6fe1b7087ed	d5c7f74b-98e2-4826-a36b-a14c398f96d8
ea214052-69ff-4b40-989c-b6fe1b7087ed	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
ea214052-69ff-4b40-989c-b6fe1b7087ed	24f29b23-290d-40b2-af73-0e40d69eebbf
ea214052-69ff-4b40-989c-b6fe1b7087ed	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
c62b165e-185c-473c-befc-0baf45c15538	d5c7f74b-98e2-4826-a36b-a14c398f96d8
c62b165e-185c-473c-befc-0baf45c15538	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
c62b165e-185c-473c-befc-0baf45c15538	24f29b23-290d-40b2-af73-0e40d69eebbf
c62b165e-185c-473c-befc-0baf45c15538	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	d5c7f74b-98e2-4826-a36b-a14c398f96d8
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	24f29b23-290d-40b2-af73-0e40d69eebbf
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
df286129-a2e2-4c29-831a-8273b63b8158	7b8a338d-49b6-4acf-a94a-e409f397abbe
df286129-a2e2-4c29-831a-8273b63b8158	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
df286129-a2e2-4c29-831a-8273b63b8158	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
9c3ee52c-a92b-4e23-be84-f04b40c9480e	7b8a338d-49b6-4acf-a94a-e409f397abbe
9c3ee52c-a92b-4e23-be84-f04b40c9480e	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
9c3ee52c-a92b-4e23-be84-f04b40c9480e	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
1f4f2f17-eac0-4bd8-a049-5fe4f3da28e5	7b8a338d-49b6-4acf-a94a-e409f397abbe
1f4f2f17-eac0-4bd8-a049-5fe4f3da28e5	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
1f4f2f17-eac0-4bd8-a049-5fe4f3da28e5	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
bed3163b-965a-41d3-84e7-82a425b6b75c	7b8a338d-49b6-4acf-a94a-e409f397abbe
bed3163b-965a-41d3-84e7-82a425b6b75c	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
bed3163b-965a-41d3-84e7-82a425b6b75c	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
88b2dd38-1772-4785-85d9-1601b312cfc8	7b8a338d-49b6-4acf-a94a-e409f397abbe
88b2dd38-1772-4785-85d9-1601b312cfc8	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9
88b2dd38-1772-4785-85d9-1601b312cfc8	3904ed8d-4348-48f4-80c5-4fb13d0a15d4
\.


--
-- Data for Name: resource_server; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_server (id, allow_rs_remote_mgmt, policy_enforce_mode, decision_strategy) FROM stdin;
f637d925-d634-4b92-ad79-fb1b387b3e2e	t	0	0
\.


--
-- Data for Name: resource_server_perm_ticket; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_server_perm_ticket (id, owner, requester, created_timestamp, granted_timestamp, resource_id, scope_id, resource_server_id, policy_id) FROM stdin;
12b241fb-5a5c-43ef-91e8-76cdf54615f7	5441cea9-fcf2-419e-bc20-948c3c283c98	97503f80-1f4f-4ae6-8b58-eb50a082acf9	1765888386727	\N	df286129-a2e2-4c29-831a-8273b63b8158	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
7764e636-adb5-4f9e-a1b0-bd9a46f53705	5441cea9-fcf2-419e-bc20-948c3c283c98	499edbce-5fcd-4a08-9ac0-113864a2afa3	1765892846173	\N	1f4f2f17-eac0-4bd8-a049-5fe4f3da28e5	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
5d6aee0d-fc34-47c5-999e-d18ea5b726ad	5441cea9-fcf2-419e-bc20-948c3c283c98	f637d925-d634-4b92-ad79-fb1b387b3e2e	1769532119846	\N	df286129-a2e2-4c29-831a-8273b63b8158	42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
\.


--
-- Data for Name: resource_server_policy; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_server_policy (id, name, description, type, decision_strategy, logic, resource_server_id, owner) FROM stdin;
98d17cf6-af9d-4ec2-bf22-3ebc75f6043c	Allow fhir-client Policy	\N	client	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
0b3e0ae3-9d52-4e27-9cce-4df78f6f1b13	Patient Access Policy	Policy for users with Patient role	role	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
f0097b3d-896d-4bca-a1a6-2f23f67c4179	Doctor Access Policy	Policy for users with Doctor role	role	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
cf031263-2240-4e3a-aa66-435d8be13bda	Administrator Access Policy	Policy for administrators with full access	role	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
5c503412-0dea-4d9d-9fd0-d9cf36f4628e	Patient or Admin Access	Allows patients to access their own data or admins to access all	aggregate	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
2a86201c-56b1-4f98-b727-16b8f55988ff	Doctor or Admin Access	Allows doctors and admins to access patient data	aggregate	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
efd93021-7e76-4202-ba03-d89330a48f66	Patient Read Own Data	Patients can read their own Patient resource	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
9661b3f8-a5f8-4e30-ac49-af00b078e62f	Patient Write Own Data	Patients can update their own Patient resource	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
18e46344-009c-4b0e-a943-c58960ee9871	Doctor Read Patient Data	Doctors can read Patient resources with permission	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
b9870a4c-1b3e-48d8-b633-b6d89910f1be	Admin Full Patient Access	Admins have full access to Patient resources	scope	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
5475198b-e4a2-40bc-8fa5-a9c9a87596f2	Patient Read Own Allergies	Patients can read their own allergy information	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
21b596be-00a8-4d19-9456-f2cb1b6e5242	Doctor Manage Allergies	Doctors can read/create/update allergy records	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
6a039833-ded3-4195-9f18-e9fc6f9e31b2	Admin Full Allergy Access	Admins have full access to allergy records	scope	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
adb786c1-c6c1-4db1-b4b1-607cab3085c7	Patient Read Own Conditions	Patients can read their own medical conditions	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
fed1f1bf-3054-4aa9-985d-17487fb0e263	Doctor Manage Conditions	Doctors can read/create/update Conditions	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
85594e45-be39-41e2-818a-75113a4d07b4	Admin Full Condition Access	Admins have full access to Conditions	scope	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
494d18f3-70fa-49b5-8e0f-b40f3c5cd258	Patient Read Own Medications	Patients can read their own medication records	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
35245166-481f-4bb9-9e7c-b31907128b21	Doctor Manage Medications	Doctors can read/create/update medication statements	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
07d1240c-0b98-4b82-90fa-7ceb09fbd5da	Admin Full Medication Access	Admins have full access to medication records	scope	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
1ef90841-93bb-443c-a405-2fb028e4c2cb	Resource Owner Policy	Grans access to resource owners	script-owner-policy.js	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
76050c35-6e2e-4ef8-8769-b4c6354116dc	Dr. Bob User Policy		user	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
647de62c-fbb7-4310-a5b6-3e4fc20d1c7d	Patient Owner Access Permission	Resource owners can access their resources	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
b3394fda-9dda-4f92-b07c-e2cbe35c2ec8	Condition Owner Access Permission	Resource owners can access their resources	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
feb85689-e557-409d-a01a-dd606952baf3	MediactionStatement Owner Access Permission	Resource owners can access their resources	scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
b142bc58-efb0-448d-9203-66894c6aac16	Dr Smith User Policy		user	1	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
31044763-9265-48d2-a508-be0cd5430292	Dr.Bob read access Condition/554		scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
d7af2a0a-2273-4768-b0c2-d85d8aca3011	Dr. Smith access to Patient 552 (alice)		scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
9a313617-6544-449e-a2aa-abb3eb9eb589	Dr Smith access to Allergy/555 (alice) scope		scope	0	0	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
\.


--
-- Data for Name: resource_server_resource; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_server_resource (id, name, type, icon_uri, owner, resource_server_id, owner_managed_access, display_name) FROM stdin;
c9e40800-c762-4f34-87fc-61f726dfb717	Default Resource	urn:fhir-client:resources:default	\N	f637d925-d634-4b92-ad79-fb1b387b3e2e	f637d925-d634-4b92-ad79-fb1b387b3e2e	f	\N
440f6acd-3eb0-45af-950f-419017359dda	PatientResource	http://localhost:8080/fhir/Patient/*		f637d925-d634-4b92-ad79-fb1b387b3e2e	f637d925-d634-4b92-ad79-fb1b387b3e2e	f	PatientResource
ea214052-69ff-4b40-989c-b6fe1b7087ed	AllergyIntoleranceResource	http://localhost:8080/fhir/AllergyIntolerance/*		f637d925-d634-4b92-ad79-fb1b387b3e2e	f637d925-d634-4b92-ad79-fb1b387b3e2e	f	AllergyIntoleranceResource
c62b165e-185c-473c-befc-0baf45c15538	MedicationStatementResource	http://localhost:8080/fhir/MedicationStatement/*		f637d925-d634-4b92-ad79-fb1b387b3e2e	f637d925-d634-4b92-ad79-fb1b387b3e2e	f	MedicationStatementResource
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	ConditionResource	http://localhost:8080/fhir/Condition/*		f637d925-d634-4b92-ad79-fb1b387b3e2e	f637d925-d634-4b92-ad79-fb1b387b3e2e	f	ConditionResource
1f4f2f17-eac0-4bd8-a049-5fe4f3da28e5	Condition/554	Condition	\N	5441cea9-fcf2-419e-bc20-948c3c283c98	f637d925-d634-4b92-ad79-fb1b387b3e2e	t	Condition/554
bed3163b-965a-41d3-84e7-82a425b6b75c	AllergyIntolerance/555	AllergyIntolerance	\N	5441cea9-fcf2-419e-bc20-948c3c283c98	f637d925-d634-4b92-ad79-fb1b387b3e2e	t	AllergyIntolerance/555
88b2dd38-1772-4785-85d9-1601b312cfc8	Patient/602	Patient		7fc0d4bd-40ca-483e-9530-6e1fe84bded3	f637d925-d634-4b92-ad79-fb1b387b3e2e	t	Patient/602
df286129-a2e2-4c29-831a-8273b63b8158	Patient/552	Patient	\N	5441cea9-fcf2-419e-bc20-948c3c283c98	f637d925-d634-4b92-ad79-fb1b387b3e2e	t	Patient/552
9c3ee52c-a92b-4e23-be84-f04b40c9480e	AllergyIntolerance/553	AllergyIntolerance	\N	5441cea9-fcf2-419e-bc20-948c3c283c98	f637d925-d634-4b92-ad79-fb1b387b3e2e	t	AllergyIntolerance/553
\.


--
-- Data for Name: resource_server_scope; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_server_scope (id, name, icon_uri, resource_server_id, display_name) FROM stdin;
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	read	\N	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
24f29b23-290d-40b2-af73-0e40d69eebbf	create	\N	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
d5c7f74b-98e2-4826-a36b-a14c398f96d8	update	\N	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	delete	\N	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
7b8a338d-49b6-4acf-a94a-e409f397abbe	write	\N	f637d925-d634-4b92-ad79-fb1b387b3e2e	\N
\.


--
-- Data for Name: resource_uris; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.resource_uris (resource_id, value) FROM stdin;
440f6acd-3eb0-45af-950f-419017359dda	http://localhost:8080/fhir/Patient/*
9988c3be-bf30-44c7-8b17-7e6323ebcc0f	http://localhost:8080/fhir/Condition/*
c62b165e-185c-473c-befc-0baf45c15538	http://localhost:8080/fhir/MedicationStatement/*
c9e40800-c762-4f34-87fc-61f726dfb717	/*
ea214052-69ff-4b40-989c-b6fe1b7087ed	http://localhost:8080/fhir/AllergyIntolerance/*
\.


--
-- Data for Name: revoked_token; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.revoked_token (id, expire) FROM stdin;
\.


--
-- Data for Name: role_attribute; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.role_attribute (id, role_id, name, value) FROM stdin;
\.


--
-- Data for Name: scope_mapping; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.scope_mapping (client_id, role_id) FROM stdin;
acf59302-35a1-4e76-895c-f9a9c7234692	60f5bc18-fe0d-43bd-adcf-cdc636e356f2
acf59302-35a1-4e76-895c-f9a9c7234692	e861c14b-e90b-472c-bdeb-e58d513389ff
157e8078-530f-467a-9072-46f2ea6627fb	8d8c96cd-4220-4b4c-8b1a-11d284791592
157e8078-530f-467a-9072-46f2ea6627fb	22b8abad-460c-464d-afae-3b6a2380d7d0
\.


--
-- Data for Name: scope_policy; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.scope_policy (scope_id, policy_id) FROM stdin;
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	efd93021-7e76-4202-ba03-d89330a48f66
d5c7f74b-98e2-4826-a36b-a14c398f96d8	9661b3f8-a5f8-4e30-ac49-af00b078e62f
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	18e46344-009c-4b0e-a943-c58960ee9871
d5c7f74b-98e2-4826-a36b-a14c398f96d8	b9870a4c-1b3e-48d8-b633-b6d89910f1be
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	b9870a4c-1b3e-48d8-b633-b6d89910f1be
24f29b23-290d-40b2-af73-0e40d69eebbf	b9870a4c-1b3e-48d8-b633-b6d89910f1be
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	b9870a4c-1b3e-48d8-b633-b6d89910f1be
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	5475198b-e4a2-40bc-8fa5-a9c9a87596f2
d5c7f74b-98e2-4826-a36b-a14c398f96d8	21b596be-00a8-4d19-9456-f2cb1b6e5242
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	21b596be-00a8-4d19-9456-f2cb1b6e5242
24f29b23-290d-40b2-af73-0e40d69eebbf	21b596be-00a8-4d19-9456-f2cb1b6e5242
d5c7f74b-98e2-4826-a36b-a14c398f96d8	6a039833-ded3-4195-9f18-e9fc6f9e31b2
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	6a039833-ded3-4195-9f18-e9fc6f9e31b2
24f29b23-290d-40b2-af73-0e40d69eebbf	6a039833-ded3-4195-9f18-e9fc6f9e31b2
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	6a039833-ded3-4195-9f18-e9fc6f9e31b2
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	adb786c1-c6c1-4db1-b4b1-607cab3085c7
d5c7f74b-98e2-4826-a36b-a14c398f96d8	fed1f1bf-3054-4aa9-985d-17487fb0e263
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	fed1f1bf-3054-4aa9-985d-17487fb0e263
24f29b23-290d-40b2-af73-0e40d69eebbf	fed1f1bf-3054-4aa9-985d-17487fb0e263
d5c7f74b-98e2-4826-a36b-a14c398f96d8	85594e45-be39-41e2-818a-75113a4d07b4
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	85594e45-be39-41e2-818a-75113a4d07b4
24f29b23-290d-40b2-af73-0e40d69eebbf	85594e45-be39-41e2-818a-75113a4d07b4
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	85594e45-be39-41e2-818a-75113a4d07b4
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	494d18f3-70fa-49b5-8e0f-b40f3c5cd258
d5c7f74b-98e2-4826-a36b-a14c398f96d8	35245166-481f-4bb9-9e7c-b31907128b21
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	35245166-481f-4bb9-9e7c-b31907128b21
24f29b23-290d-40b2-af73-0e40d69eebbf	35245166-481f-4bb9-9e7c-b31907128b21
d5c7f74b-98e2-4826-a36b-a14c398f96d8	07d1240c-0b98-4b82-90fa-7ceb09fbd5da
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	07d1240c-0b98-4b82-90fa-7ceb09fbd5da
24f29b23-290d-40b2-af73-0e40d69eebbf	07d1240c-0b98-4b82-90fa-7ceb09fbd5da
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	07d1240c-0b98-4b82-90fa-7ceb09fbd5da
7b8a338d-49b6-4acf-a94a-e409f397abbe	647de62c-fbb7-4310-a5b6-3e4fc20d1c7d
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	647de62c-fbb7-4310-a5b6-3e4fc20d1c7d
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	647de62c-fbb7-4310-a5b6-3e4fc20d1c7d
7b8a338d-49b6-4acf-a94a-e409f397abbe	b3394fda-9dda-4f92-b07c-e2cbe35c2ec8
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	b3394fda-9dda-4f92-b07c-e2cbe35c2ec8
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	b3394fda-9dda-4f92-b07c-e2cbe35c2ec8
7b8a338d-49b6-4acf-a94a-e409f397abbe	feb85689-e557-409d-a01a-dd606952baf3
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	feb85689-e557-409d-a01a-dd606952baf3
3904ed8d-4348-48f4-80c5-4fb13d0a15d4	feb85689-e557-409d-a01a-dd606952baf3
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	d7af2a0a-2273-4768-b0c2-d85d8aca3011
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	31044763-9265-48d2-a508-be0cd5430292
42e3a910-0b64-4cb5-8fcb-b0bb7605f1a9	9a313617-6544-449e-a2aa-abb3eb9eb589
\.


--
-- Data for Name: server_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.server_config (server_config_key, value, version) FROM stdin;
\.


--
-- Data for Name: user_attribute; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_attribute (name, value, user_id, id, long_value_hash, long_value_hash_lower_case, long_value) FROM stdin;
is_temporary_admin	true	b9db48fc-0c61-4a58-adc4-60a3f190fd93	2050e980-d682-474e-a895-ab1d523c2e40	\N	\N	\N
\.


--
-- Data for Name: user_consent; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_consent (id, client_id, user_id, created_date, last_updated_date, client_storage_provider, external_client_id) FROM stdin;
\.


--
-- Data for Name: user_consent_client_scope; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_consent_client_scope (user_consent_id, scope_id) FROM stdin;
\.


--
-- Data for Name: user_entity; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_entity (id, email, email_constraint, email_verified, enabled, federation_link, first_name, last_name, realm_id, username, created_timestamp, service_account_client_link, not_before) FROM stdin;
6c1d215e-d5cb-4117-af89-cd6988ce3138	\N	7242d1c3-6756-4d99-810a-68cbdb204aa8	f	t	\N	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	service-account-fhir-client	1734354372391	f637d925-d634-4b92-ad79-fb1b387b3e2e	0
b9db48fc-0c61-4a58-adc4-60a3f190fd93	\N	4ad4edc0-d1f3-4227-803c-d3c38d0c8e56	f	t	\N	\N	\N	955a00d0-1411-4e86-8ef2-bdedffd7a66f	admin	1765804766453	\N	0
7fc0d4bd-40ca-483e-9530-6e1fe84bded3	system@hospital.org	system@hospital.org	t	f	\N	\N	\N	27d57df0-0794-4e96-92ac-85b802200864	system-placeholder	1765806988834	\N	0
5441cea9-fcf2-419e-bc20-948c3c283c98	alice@example.com	alice@example.com	t	t	\N	Alice	Smith	27d57df0-0794-4e96-92ac-85b802200864	alice	1765807580501	\N	0
97503f80-1f4f-4ae6-8b58-eb50a082acf9	dr.bob@example.com	dr.bob@example.com	t	t	\N	Bob	Anderson	27d57df0-0794-4e96-92ac-85b802200864	dr.bob	1765807650088	\N	0
df11bc00-e0e6-4924-941d-3627fdd16992	jan@admin.com	jan@admin.com	t	t	\N	Jan	Meyer	27d57df0-0794-4e96-92ac-85b802200864	jan	1765807681777	\N	0
499edbce-5fcd-4a08-9ac0-113864a2afa3	dr.smith@example.com	dr.smith@example.com	t	t	\N	John	Smith	27d57df0-0794-4e96-92ac-85b802200864	dr.smith	1765892153207	\N	0
\.


--
-- Data for Name: user_federation_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_federation_config (user_federation_provider_id, value, name) FROM stdin;
\.


--
-- Data for Name: user_federation_mapper; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_federation_mapper (id, name, federation_provider_id, federation_mapper_type, realm_id) FROM stdin;
\.


--
-- Data for Name: user_federation_mapper_config; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_federation_mapper_config (user_federation_mapper_id, value, name) FROM stdin;
\.


--
-- Data for Name: user_federation_provider; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_federation_provider (id, changed_sync_period, display_name, full_sync_period, last_sync, priority, provider_name, realm_id) FROM stdin;
\.


--
-- Data for Name: user_group_membership; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_group_membership (group_id, user_id, membership_type) FROM stdin;
\.


--
-- Data for Name: user_required_action; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_required_action (user_id, required_action) FROM stdin;
\.


--
-- Data for Name: user_role_mapping; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.user_role_mapping (role_id, user_id) FROM stdin;
39c3feae-b3f5-49b1-a6cf-1f91960d022d	6c1d215e-d5cb-4117-af89-cd6988ce3138
12d01785-a93c-419d-8161-71201cfc13a2	6c1d215e-d5cb-4117-af89-cd6988ce3138
b6629199-585d-40b5-b152-867da4feec38	6c1d215e-d5cb-4117-af89-cd6988ce3138
74bbf2b8-0473-4e83-a487-af069f08b188	b9db48fc-0c61-4a58-adc4-60a3f190fd93
417a29f4-aa8b-4560-9f73-eafc6a417349	b9db48fc-0c61-4a58-adc4-60a3f190fd93
39c3feae-b3f5-49b1-a6cf-1f91960d022d	7fc0d4bd-40ca-483e-9530-6e1fe84bded3
39c3feae-b3f5-49b1-a6cf-1f91960d022d	5441cea9-fcf2-419e-bc20-948c3c283c98
1c35c95b-4c5c-4645-8eba-ef030193f04e	5441cea9-fcf2-419e-bc20-948c3c283c98
39c3feae-b3f5-49b1-a6cf-1f91960d022d	97503f80-1f4f-4ae6-8b58-eb50a082acf9
b627b089-53d9-44f8-a4af-5e013848ac9a	97503f80-1f4f-4ae6-8b58-eb50a082acf9
39c3feae-b3f5-49b1-a6cf-1f91960d022d	df11bc00-e0e6-4924-941d-3627fdd16992
9db8f464-eccb-4967-be8d-7e7d934a661e	df11bc00-e0e6-4924-941d-3627fdd16992
39c3feae-b3f5-49b1-a6cf-1f91960d022d	499edbce-5fcd-4a08-9ac0-113864a2afa3
b627b089-53d9-44f8-a4af-5e013848ac9a	499edbce-5fcd-4a08-9ac0-113864a2afa3
\.


--
-- Data for Name: web_origins; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.web_origins (client_id, value) FROM stdin;
247c0e1e-e295-45ea-904d-824e58645759	+
f637d925-d634-4b92-ad79-fb1b387b3e2e	http://localhost:8080/
60c887d6-2ce7-4fe9-98f0-fe2625266194	+
\.


--
-- Data for Name: workflow_state; Type: TABLE DATA; Schema: public; Owner: keycloak
--

COPY public.workflow_state (execution_id, resource_id, workflow_id, workflow_provider_id, resource_type, scheduled_step_id, scheduled_step_timestamp) FROM stdin;
\.


--
-- Name: org_domain ORG_DOMAIN_pkey; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.org_domain
    ADD CONSTRAINT "ORG_DOMAIN_pkey" PRIMARY KEY (id, name);


--
-- Name: org ORG_pkey; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT "ORG_pkey" PRIMARY KEY (id);


--
-- Name: server_config SERVER_CONFIG_pkey; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.server_config
    ADD CONSTRAINT "SERVER_CONFIG_pkey" PRIMARY KEY (server_config_key);


--
-- Name: keycloak_role UK_J3RWUVD56ONTGSUHOGM184WW2-2; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.keycloak_role
    ADD CONSTRAINT "UK_J3RWUVD56ONTGSUHOGM184WW2-2" UNIQUE (name, client_realm_constraint);


--
-- Name: client_auth_flow_bindings c_cli_flow_bind; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_auth_flow_bindings
    ADD CONSTRAINT c_cli_flow_bind PRIMARY KEY (client_id, binding_name);


--
-- Name: client_scope_client c_cli_scope_bind; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_scope_client
    ADD CONSTRAINT c_cli_scope_bind PRIMARY KEY (client_id, scope_id);


--
-- Name: client_initial_access cnstr_client_init_acc_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_initial_access
    ADD CONSTRAINT cnstr_client_init_acc_pk PRIMARY KEY (id);


--
-- Name: realm_default_groups con_group_id_def_groups; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_default_groups
    ADD CONSTRAINT con_group_id_def_groups UNIQUE (group_id);


--
-- Name: broker_link constr_broker_link_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.broker_link
    ADD CONSTRAINT constr_broker_link_pk PRIMARY KEY (identity_provider, user_id);


--
-- Name: component_config constr_component_config_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.component_config
    ADD CONSTRAINT constr_component_config_pk PRIMARY KEY (id);


--
-- Name: component constr_component_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.component
    ADD CONSTRAINT constr_component_pk PRIMARY KEY (id);


--
-- Name: fed_user_required_action constr_fed_required_action; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.fed_user_required_action
    ADD CONSTRAINT constr_fed_required_action PRIMARY KEY (required_action, user_id);


--
-- Name: fed_user_attribute constr_fed_user_attr_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.fed_user_attribute
    ADD CONSTRAINT constr_fed_user_attr_pk PRIMARY KEY (id);


--
-- Name: fed_user_consent constr_fed_user_consent_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.fed_user_consent
    ADD CONSTRAINT constr_fed_user_consent_pk PRIMARY KEY (id);


--
-- Name: fed_user_credential constr_fed_user_cred_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.fed_user_credential
    ADD CONSTRAINT constr_fed_user_cred_pk PRIMARY KEY (id);


--
-- Name: fed_user_group_membership constr_fed_user_group; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.fed_user_group_membership
    ADD CONSTRAINT constr_fed_user_group PRIMARY KEY (group_id, user_id);


--
-- Name: fed_user_role_mapping constr_fed_user_role; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.fed_user_role_mapping
    ADD CONSTRAINT constr_fed_user_role PRIMARY KEY (role_id, user_id);


--
-- Name: federated_user constr_federated_user; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.federated_user
    ADD CONSTRAINT constr_federated_user PRIMARY KEY (id);


--
-- Name: realm_default_groups constr_realm_default_groups; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_default_groups
    ADD CONSTRAINT constr_realm_default_groups PRIMARY KEY (realm_id, group_id);


--
-- Name: realm_enabled_event_types constr_realm_enabl_event_types; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_enabled_event_types
    ADD CONSTRAINT constr_realm_enabl_event_types PRIMARY KEY (realm_id, value);


--
-- Name: realm_events_listeners constr_realm_events_listeners; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_events_listeners
    ADD CONSTRAINT constr_realm_events_listeners PRIMARY KEY (realm_id, value);


--
-- Name: realm_supported_locales constr_realm_supported_locales; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_supported_locales
    ADD CONSTRAINT constr_realm_supported_locales PRIMARY KEY (realm_id, value);


--
-- Name: identity_provider constraint_2b; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.identity_provider
    ADD CONSTRAINT constraint_2b PRIMARY KEY (internal_id);


--
-- Name: client_attributes constraint_3c; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_attributes
    ADD CONSTRAINT constraint_3c PRIMARY KEY (client_id, name);


--
-- Name: event_entity constraint_4; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.event_entity
    ADD CONSTRAINT constraint_4 PRIMARY KEY (id);


--
-- Name: federated_identity constraint_40; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.federated_identity
    ADD CONSTRAINT constraint_40 PRIMARY KEY (identity_provider, user_id);


--
-- Name: realm constraint_4a; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm
    ADD CONSTRAINT constraint_4a PRIMARY KEY (id);


--
-- Name: user_federation_provider constraint_5c; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_provider
    ADD CONSTRAINT constraint_5c PRIMARY KEY (id);


--
-- Name: client constraint_7; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT constraint_7 PRIMARY KEY (id);


--
-- Name: scope_mapping constraint_81; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.scope_mapping
    ADD CONSTRAINT constraint_81 PRIMARY KEY (client_id, role_id);


--
-- Name: client_node_registrations constraint_84; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_node_registrations
    ADD CONSTRAINT constraint_84 PRIMARY KEY (client_id, name);


--
-- Name: realm_attribute constraint_9; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_attribute
    ADD CONSTRAINT constraint_9 PRIMARY KEY (name, realm_id);


--
-- Name: realm_required_credential constraint_92; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_required_credential
    ADD CONSTRAINT constraint_92 PRIMARY KEY (realm_id, type);


--
-- Name: keycloak_role constraint_a; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.keycloak_role
    ADD CONSTRAINT constraint_a PRIMARY KEY (id);


--
-- Name: admin_event_entity constraint_admin_event_entity; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.admin_event_entity
    ADD CONSTRAINT constraint_admin_event_entity PRIMARY KEY (id);


--
-- Name: authenticator_config_entry constraint_auth_cfg_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authenticator_config_entry
    ADD CONSTRAINT constraint_auth_cfg_pk PRIMARY KEY (authenticator_id, name);


--
-- Name: authentication_execution constraint_auth_exec_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authentication_execution
    ADD CONSTRAINT constraint_auth_exec_pk PRIMARY KEY (id);


--
-- Name: authentication_flow constraint_auth_flow_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authentication_flow
    ADD CONSTRAINT constraint_auth_flow_pk PRIMARY KEY (id);


--
-- Name: authenticator_config constraint_auth_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authenticator_config
    ADD CONSTRAINT constraint_auth_pk PRIMARY KEY (id);


--
-- Name: user_role_mapping constraint_c; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_role_mapping
    ADD CONSTRAINT constraint_c PRIMARY KEY (role_id, user_id);


--
-- Name: composite_role constraint_composite_role; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.composite_role
    ADD CONSTRAINT constraint_composite_role PRIMARY KEY (composite, child_role);


--
-- Name: identity_provider_config constraint_d; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.identity_provider_config
    ADD CONSTRAINT constraint_d PRIMARY KEY (identity_provider_id, name);


--
-- Name: policy_config constraint_dpc; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.policy_config
    ADD CONSTRAINT constraint_dpc PRIMARY KEY (policy_id, name);


--
-- Name: realm_smtp_config constraint_e; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_smtp_config
    ADD CONSTRAINT constraint_e PRIMARY KEY (realm_id, name);


--
-- Name: credential constraint_f; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.credential
    ADD CONSTRAINT constraint_f PRIMARY KEY (id);


--
-- Name: user_federation_config constraint_f9; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_config
    ADD CONSTRAINT constraint_f9 PRIMARY KEY (user_federation_provider_id, name);


--
-- Name: resource_server_perm_ticket constraint_fapmt; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT constraint_fapmt PRIMARY KEY (id);


--
-- Name: resource_server_resource constraint_farsr; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_resource
    ADD CONSTRAINT constraint_farsr PRIMARY KEY (id);


--
-- Name: resource_server_policy constraint_farsrp; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_policy
    ADD CONSTRAINT constraint_farsrp PRIMARY KEY (id);


--
-- Name: associated_policy constraint_farsrpap; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.associated_policy
    ADD CONSTRAINT constraint_farsrpap PRIMARY KEY (policy_id, associated_policy_id);


--
-- Name: resource_policy constraint_farsrpp; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_policy
    ADD CONSTRAINT constraint_farsrpp PRIMARY KEY (resource_id, policy_id);


--
-- Name: resource_server_scope constraint_farsrs; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_scope
    ADD CONSTRAINT constraint_farsrs PRIMARY KEY (id);


--
-- Name: resource_scope constraint_farsrsp; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_scope
    ADD CONSTRAINT constraint_farsrsp PRIMARY KEY (resource_id, scope_id);


--
-- Name: scope_policy constraint_farsrsps; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.scope_policy
    ADD CONSTRAINT constraint_farsrsps PRIMARY KEY (scope_id, policy_id);


--
-- Name: user_entity constraint_fb; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_entity
    ADD CONSTRAINT constraint_fb PRIMARY KEY (id);


--
-- Name: user_federation_mapper_config constraint_fedmapper_cfg_pm; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_mapper_config
    ADD CONSTRAINT constraint_fedmapper_cfg_pm PRIMARY KEY (user_federation_mapper_id, name);


--
-- Name: user_federation_mapper constraint_fedmapperpm; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_mapper
    ADD CONSTRAINT constraint_fedmapperpm PRIMARY KEY (id);


--
-- Name: fed_user_consent_cl_scope constraint_fgrntcsnt_clsc_pm; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.fed_user_consent_cl_scope
    ADD CONSTRAINT constraint_fgrntcsnt_clsc_pm PRIMARY KEY (user_consent_id, scope_id);


--
-- Name: user_consent_client_scope constraint_grntcsnt_clsc_pm; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_consent_client_scope
    ADD CONSTRAINT constraint_grntcsnt_clsc_pm PRIMARY KEY (user_consent_id, scope_id);


--
-- Name: user_consent constraint_grntcsnt_pm; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT constraint_grntcsnt_pm PRIMARY KEY (id);


--
-- Name: keycloak_group constraint_group; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.keycloak_group
    ADD CONSTRAINT constraint_group PRIMARY KEY (id);


--
-- Name: group_attribute constraint_group_attribute_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.group_attribute
    ADD CONSTRAINT constraint_group_attribute_pk PRIMARY KEY (id);


--
-- Name: group_role_mapping constraint_group_role; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.group_role_mapping
    ADD CONSTRAINT constraint_group_role PRIMARY KEY (role_id, group_id);


--
-- Name: identity_provider_mapper constraint_idpm; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.identity_provider_mapper
    ADD CONSTRAINT constraint_idpm PRIMARY KEY (id);


--
-- Name: idp_mapper_config constraint_idpmconfig; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.idp_mapper_config
    ADD CONSTRAINT constraint_idpmconfig PRIMARY KEY (idp_mapper_id, name);


--
-- Name: jgroups_ping constraint_jgroups_ping; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.jgroups_ping
    ADD CONSTRAINT constraint_jgroups_ping PRIMARY KEY (address);


--
-- Name: migration_model constraint_migmod; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.migration_model
    ADD CONSTRAINT constraint_migmod PRIMARY KEY (id);


--
-- Name: offline_client_session constraint_offl_cl_ses_pk3; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.offline_client_session
    ADD CONSTRAINT constraint_offl_cl_ses_pk3 PRIMARY KEY (user_session_id, client_id, client_storage_provider, external_client_id, offline_flag);


--
-- Name: offline_user_session constraint_offl_us_ses_pk2; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.offline_user_session
    ADD CONSTRAINT constraint_offl_us_ses_pk2 PRIMARY KEY (user_session_id, offline_flag);


--
-- Name: protocol_mapper constraint_pcm; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.protocol_mapper
    ADD CONSTRAINT constraint_pcm PRIMARY KEY (id);


--
-- Name: protocol_mapper_config constraint_pmconfig; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.protocol_mapper_config
    ADD CONSTRAINT constraint_pmconfig PRIMARY KEY (protocol_mapper_id, name);


--
-- Name: redirect_uris constraint_redirect_uris; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.redirect_uris
    ADD CONSTRAINT constraint_redirect_uris PRIMARY KEY (client_id, value);


--
-- Name: required_action_config constraint_req_act_cfg_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.required_action_config
    ADD CONSTRAINT constraint_req_act_cfg_pk PRIMARY KEY (required_action_id, name);


--
-- Name: required_action_provider constraint_req_act_prv_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.required_action_provider
    ADD CONSTRAINT constraint_req_act_prv_pk PRIMARY KEY (id);


--
-- Name: user_required_action constraint_required_action; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_required_action
    ADD CONSTRAINT constraint_required_action PRIMARY KEY (required_action, user_id);


--
-- Name: resource_uris constraint_resour_uris_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_uris
    ADD CONSTRAINT constraint_resour_uris_pk PRIMARY KEY (resource_id, value);


--
-- Name: role_attribute constraint_role_attribute_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.role_attribute
    ADD CONSTRAINT constraint_role_attribute_pk PRIMARY KEY (id);


--
-- Name: revoked_token constraint_rt; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.revoked_token
    ADD CONSTRAINT constraint_rt PRIMARY KEY (id);


--
-- Name: user_attribute constraint_user_attribute_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_attribute
    ADD CONSTRAINT constraint_user_attribute_pk PRIMARY KEY (id);


--
-- Name: user_group_membership constraint_user_group; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_group_membership
    ADD CONSTRAINT constraint_user_group PRIMARY KEY (group_id, user_id);


--
-- Name: web_origins constraint_web_origins; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.web_origins
    ADD CONSTRAINT constraint_web_origins PRIMARY KEY (client_id, value);


--
-- Name: databasechangeloglock databasechangeloglock_pkey; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.databasechangeloglock
    ADD CONSTRAINT databasechangeloglock_pkey PRIMARY KEY (id);


--
-- Name: client_scope_attributes pk_cl_tmpl_attr; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_scope_attributes
    ADD CONSTRAINT pk_cl_tmpl_attr PRIMARY KEY (scope_id, name);


--
-- Name: client_scope pk_cli_template; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_scope
    ADD CONSTRAINT pk_cli_template PRIMARY KEY (id);


--
-- Name: resource_server pk_resource_server; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server
    ADD CONSTRAINT pk_resource_server PRIMARY KEY (id);


--
-- Name: client_scope_role_mapping pk_template_scope; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_scope_role_mapping
    ADD CONSTRAINT pk_template_scope PRIMARY KEY (scope_id, role_id);


--
-- Name: workflow_state pk_workflow_state; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.workflow_state
    ADD CONSTRAINT pk_workflow_state PRIMARY KEY (execution_id);


--
-- Name: default_client_scope r_def_cli_scope_bind; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.default_client_scope
    ADD CONSTRAINT r_def_cli_scope_bind PRIMARY KEY (realm_id, scope_id);


--
-- Name: realm_localizations realm_localizations_pkey; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_localizations
    ADD CONSTRAINT realm_localizations_pkey PRIMARY KEY (realm_id, locale);


--
-- Name: resource_attribute res_attr_pk; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_attribute
    ADD CONSTRAINT res_attr_pk PRIMARY KEY (id);


--
-- Name: keycloak_group sibling_names; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.keycloak_group
    ADD CONSTRAINT sibling_names UNIQUE (realm_id, parent_group, name);


--
-- Name: identity_provider uk_2daelwnibji49avxsrtuf6xj33; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.identity_provider
    ADD CONSTRAINT uk_2daelwnibji49avxsrtuf6xj33 UNIQUE (provider_alias, realm_id);


--
-- Name: client uk_b71cjlbenv945rb6gcon438at; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT uk_b71cjlbenv945rb6gcon438at UNIQUE (realm_id, client_id);


--
-- Name: client_scope uk_cli_scope; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_scope
    ADD CONSTRAINT uk_cli_scope UNIQUE (realm_id, name);


--
-- Name: user_entity uk_dykn684sl8up1crfei6eckhd7; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_entity
    ADD CONSTRAINT uk_dykn684sl8up1crfei6eckhd7 UNIQUE (realm_id, email_constraint);


--
-- Name: user_consent uk_external_consent; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT uk_external_consent UNIQUE (client_storage_provider, external_client_id, user_id);


--
-- Name: resource_server_resource uk_frsr6t700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_resource
    ADD CONSTRAINT uk_frsr6t700s9v50bu18ws5ha6 UNIQUE (name, owner, resource_server_id);


--
-- Name: resource_server_perm_ticket uk_frsr6t700s9v50bu18ws5pmt; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT uk_frsr6t700s9v50bu18ws5pmt UNIQUE (owner, requester, resource_server_id, resource_id, scope_id);


--
-- Name: resource_server_policy uk_frsrpt700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_policy
    ADD CONSTRAINT uk_frsrpt700s9v50bu18ws5ha6 UNIQUE (name, resource_server_id);


--
-- Name: resource_server_scope uk_frsrst700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_scope
    ADD CONSTRAINT uk_frsrst700s9v50bu18ws5ha6 UNIQUE (name, resource_server_id);


--
-- Name: user_consent uk_local_consent; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT uk_local_consent UNIQUE (client_id, user_id);


--
-- Name: migration_model uk_migration_update_time; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.migration_model
    ADD CONSTRAINT uk_migration_update_time UNIQUE (update_time);


--
-- Name: migration_model uk_migration_version; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.migration_model
    ADD CONSTRAINT uk_migration_version UNIQUE (version);


--
-- Name: org uk_org_alias; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT uk_org_alias UNIQUE (realm_id, alias);


--
-- Name: org uk_org_group; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT uk_org_group UNIQUE (group_id);


--
-- Name: org uk_org_name; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT uk_org_name UNIQUE (realm_id, name);


--
-- Name: realm uk_orvsdmla56612eaefiq6wl5oi; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm
    ADD CONSTRAINT uk_orvsdmla56612eaefiq6wl5oi UNIQUE (name);


--
-- Name: user_entity uk_ru8tt6t700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_entity
    ADD CONSTRAINT uk_ru8tt6t700s9v50bu18ws5ha6 UNIQUE (realm_id, username);


--
-- Name: workflow_state uq_workflow_resource; Type: CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.workflow_state
    ADD CONSTRAINT uq_workflow_resource UNIQUE (workflow_id, resource_id);


--
-- Name: fed_user_attr_long_values; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX fed_user_attr_long_values ON public.fed_user_attribute USING btree (long_value_hash, name);


--
-- Name: fed_user_attr_long_values_lower_case; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX fed_user_attr_long_values_lower_case ON public.fed_user_attribute USING btree (long_value_hash_lower_case, name);


--
-- Name: idx_admin_event_time; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_admin_event_time ON public.admin_event_entity USING btree (realm_id, admin_event_time);


--
-- Name: idx_assoc_pol_assoc_pol_id; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_assoc_pol_assoc_pol_id ON public.associated_policy USING btree (associated_policy_id);


--
-- Name: idx_auth_config_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_auth_config_realm ON public.authenticator_config USING btree (realm_id);


--
-- Name: idx_auth_exec_flow; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_auth_exec_flow ON public.authentication_execution USING btree (flow_id);


--
-- Name: idx_auth_exec_realm_flow; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_auth_exec_realm_flow ON public.authentication_execution USING btree (realm_id, flow_id);


--
-- Name: idx_auth_flow_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_auth_flow_realm ON public.authentication_flow USING btree (realm_id);


--
-- Name: idx_cl_clscope; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_cl_clscope ON public.client_scope_client USING btree (scope_id);


--
-- Name: idx_client_att_by_name_value; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_client_att_by_name_value ON public.client_attributes USING btree (name, substr(value, 1, 255));


--
-- Name: idx_client_id; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_client_id ON public.client USING btree (client_id);


--
-- Name: idx_client_init_acc_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_client_init_acc_realm ON public.client_initial_access USING btree (realm_id);


--
-- Name: idx_clscope_attrs; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_clscope_attrs ON public.client_scope_attributes USING btree (scope_id);


--
-- Name: idx_clscope_cl; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_clscope_cl ON public.client_scope_client USING btree (client_id);


--
-- Name: idx_clscope_protmap; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_clscope_protmap ON public.protocol_mapper USING btree (client_scope_id);


--
-- Name: idx_clscope_role; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_clscope_role ON public.client_scope_role_mapping USING btree (scope_id);


--
-- Name: idx_compo_config_compo; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_compo_config_compo ON public.component_config USING btree (component_id);


--
-- Name: idx_component_provider_type; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_component_provider_type ON public.component USING btree (provider_type);


--
-- Name: idx_component_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_component_realm ON public.component USING btree (realm_id);


--
-- Name: idx_composite; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_composite ON public.composite_role USING btree (composite);


--
-- Name: idx_composite_child; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_composite_child ON public.composite_role USING btree (child_role);


--
-- Name: idx_defcls_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_defcls_realm ON public.default_client_scope USING btree (realm_id);


--
-- Name: idx_defcls_scope; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_defcls_scope ON public.default_client_scope USING btree (scope_id);


--
-- Name: idx_event_entity_user_id_type; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_event_entity_user_id_type ON public.event_entity USING btree (user_id, type, event_time);


--
-- Name: idx_event_time; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_event_time ON public.event_entity USING btree (realm_id, event_time);


--
-- Name: idx_fedidentity_feduser; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fedidentity_feduser ON public.federated_identity USING btree (federated_user_id);


--
-- Name: idx_fedidentity_user; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fedidentity_user ON public.federated_identity USING btree (user_id);


--
-- Name: idx_fu_attribute; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_attribute ON public.fed_user_attribute USING btree (user_id, realm_id, name);


--
-- Name: idx_fu_cnsnt_ext; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_cnsnt_ext ON public.fed_user_consent USING btree (user_id, client_storage_provider, external_client_id);


--
-- Name: idx_fu_consent; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_consent ON public.fed_user_consent USING btree (user_id, client_id);


--
-- Name: idx_fu_consent_ru; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_consent_ru ON public.fed_user_consent USING btree (realm_id, user_id);


--
-- Name: idx_fu_credential; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_credential ON public.fed_user_credential USING btree (user_id, type);


--
-- Name: idx_fu_credential_ru; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_credential_ru ON public.fed_user_credential USING btree (realm_id, user_id);


--
-- Name: idx_fu_group_membership; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_group_membership ON public.fed_user_group_membership USING btree (user_id, group_id);


--
-- Name: idx_fu_group_membership_ru; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_group_membership_ru ON public.fed_user_group_membership USING btree (realm_id, user_id);


--
-- Name: idx_fu_required_action; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_required_action ON public.fed_user_required_action USING btree (user_id, required_action);


--
-- Name: idx_fu_required_action_ru; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_required_action_ru ON public.fed_user_required_action USING btree (realm_id, user_id);


--
-- Name: idx_fu_role_mapping; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_role_mapping ON public.fed_user_role_mapping USING btree (user_id, role_id);


--
-- Name: idx_fu_role_mapping_ru; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_fu_role_mapping_ru ON public.fed_user_role_mapping USING btree (realm_id, user_id);


--
-- Name: idx_group_att_by_name_value; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_group_att_by_name_value ON public.group_attribute USING btree (name, ((value)::character varying(250)));


--
-- Name: idx_group_attr_group; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_group_attr_group ON public.group_attribute USING btree (group_id);


--
-- Name: idx_group_role_mapp_group; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_group_role_mapp_group ON public.group_role_mapping USING btree (group_id);


--
-- Name: idx_id_prov_mapp_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_id_prov_mapp_realm ON public.identity_provider_mapper USING btree (realm_id);


--
-- Name: idx_ident_prov_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_ident_prov_realm ON public.identity_provider USING btree (realm_id);


--
-- Name: idx_idp_for_login; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_idp_for_login ON public.identity_provider USING btree (realm_id, enabled, link_only, hide_on_login, organization_id);


--
-- Name: idx_idp_realm_org; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_idp_realm_org ON public.identity_provider USING btree (realm_id, organization_id);


--
-- Name: idx_keycloak_role_client; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_keycloak_role_client ON public.keycloak_role USING btree (client);


--
-- Name: idx_keycloak_role_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_keycloak_role_realm ON public.keycloak_role USING btree (realm);


--
-- Name: idx_offline_css_by_client; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_offline_css_by_client ON public.offline_client_session USING btree (client_id, offline_flag) WHERE ((client_id)::text <> 'external'::text);


--
-- Name: idx_offline_css_by_client_storage_provider; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_offline_css_by_client_storage_provider ON public.offline_client_session USING btree (client_storage_provider, external_client_id, offline_flag) WHERE ((client_storage_provider)::text <> 'internal'::text);


--
-- Name: idx_offline_uss_by_broker_session_id; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_offline_uss_by_broker_session_id ON public.offline_user_session USING btree (broker_session_id, realm_id);


--
-- Name: idx_offline_uss_by_last_session_refresh; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_offline_uss_by_last_session_refresh ON public.offline_user_session USING btree (realm_id, offline_flag, last_session_refresh);


--
-- Name: idx_offline_uss_by_user; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_offline_uss_by_user ON public.offline_user_session USING btree (user_id, realm_id, offline_flag);


--
-- Name: idx_org_domain_org_id; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_org_domain_org_id ON public.org_domain USING btree (org_id);


--
-- Name: idx_perm_ticket_owner; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_perm_ticket_owner ON public.resource_server_perm_ticket USING btree (owner);


--
-- Name: idx_perm_ticket_requester; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_perm_ticket_requester ON public.resource_server_perm_ticket USING btree (requester);


--
-- Name: idx_protocol_mapper_client; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_protocol_mapper_client ON public.protocol_mapper USING btree (client_id);


--
-- Name: idx_realm_attr_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_realm_attr_realm ON public.realm_attribute USING btree (realm_id);


--
-- Name: idx_realm_clscope; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_realm_clscope ON public.client_scope USING btree (realm_id);


--
-- Name: idx_realm_def_grp_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_realm_def_grp_realm ON public.realm_default_groups USING btree (realm_id);


--
-- Name: idx_realm_evt_list_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_realm_evt_list_realm ON public.realm_events_listeners USING btree (realm_id);


--
-- Name: idx_realm_evt_types_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_realm_evt_types_realm ON public.realm_enabled_event_types USING btree (realm_id);


--
-- Name: idx_realm_master_adm_cli; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_realm_master_adm_cli ON public.realm USING btree (master_admin_client);


--
-- Name: idx_realm_supp_local_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_realm_supp_local_realm ON public.realm_supported_locales USING btree (realm_id);


--
-- Name: idx_redir_uri_client; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_redir_uri_client ON public.redirect_uris USING btree (client_id);


--
-- Name: idx_req_act_prov_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_req_act_prov_realm ON public.required_action_provider USING btree (realm_id);


--
-- Name: idx_res_policy_policy; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_res_policy_policy ON public.resource_policy USING btree (policy_id);


--
-- Name: idx_res_scope_scope; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_res_scope_scope ON public.resource_scope USING btree (scope_id);


--
-- Name: idx_res_serv_pol_res_serv; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_res_serv_pol_res_serv ON public.resource_server_policy USING btree (resource_server_id);


--
-- Name: idx_res_srv_res_res_srv; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_res_srv_res_res_srv ON public.resource_server_resource USING btree (resource_server_id);


--
-- Name: idx_res_srv_scope_res_srv; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_res_srv_scope_res_srv ON public.resource_server_scope USING btree (resource_server_id);


--
-- Name: idx_rev_token_on_expire; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_rev_token_on_expire ON public.revoked_token USING btree (expire);


--
-- Name: idx_role_attribute; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_role_attribute ON public.role_attribute USING btree (role_id);


--
-- Name: idx_role_clscope; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_role_clscope ON public.client_scope_role_mapping USING btree (role_id);


--
-- Name: idx_scope_mapping_role; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_scope_mapping_role ON public.scope_mapping USING btree (role_id);


--
-- Name: idx_scope_policy_policy; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_scope_policy_policy ON public.scope_policy USING btree (policy_id);


--
-- Name: idx_update_time; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_update_time ON public.migration_model USING btree (update_time);


--
-- Name: idx_usconsent_clscope; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_usconsent_clscope ON public.user_consent_client_scope USING btree (user_consent_id);


--
-- Name: idx_usconsent_scope_id; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_usconsent_scope_id ON public.user_consent_client_scope USING btree (scope_id);


--
-- Name: idx_user_attribute; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_attribute ON public.user_attribute USING btree (user_id);


--
-- Name: idx_user_attribute_name; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_attribute_name ON public.user_attribute USING btree (name, value);


--
-- Name: idx_user_consent; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_consent ON public.user_consent USING btree (user_id);


--
-- Name: idx_user_credential; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_credential ON public.credential USING btree (user_id);


--
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_email ON public.user_entity USING btree (email);


--
-- Name: idx_user_group_mapping; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_group_mapping ON public.user_group_membership USING btree (user_id);


--
-- Name: idx_user_reqactions; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_reqactions ON public.user_required_action USING btree (user_id);


--
-- Name: idx_user_role_mapping; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_role_mapping ON public.user_role_mapping USING btree (user_id);


--
-- Name: idx_user_service_account; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_user_service_account ON public.user_entity USING btree (realm_id, service_account_client_link);


--
-- Name: idx_usr_fed_map_fed_prv; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_usr_fed_map_fed_prv ON public.user_federation_mapper USING btree (federation_provider_id);


--
-- Name: idx_usr_fed_map_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_usr_fed_map_realm ON public.user_federation_mapper USING btree (realm_id);


--
-- Name: idx_usr_fed_prv_realm; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_usr_fed_prv_realm ON public.user_federation_provider USING btree (realm_id);


--
-- Name: idx_web_orig_client; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_web_orig_client ON public.web_origins USING btree (client_id);


--
-- Name: idx_workflow_state_provider; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_workflow_state_provider ON public.workflow_state USING btree (resource_id, workflow_provider_id);


--
-- Name: idx_workflow_state_step; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX idx_workflow_state_step ON public.workflow_state USING btree (workflow_id, scheduled_step_id);


--
-- Name: user_attr_long_values; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX user_attr_long_values ON public.user_attribute USING btree (long_value_hash, name);


--
-- Name: user_attr_long_values_lower_case; Type: INDEX; Schema: public; Owner: keycloak
--

CREATE INDEX user_attr_long_values_lower_case ON public.user_attribute USING btree (long_value_hash_lower_case, name);


--
-- Name: identity_provider fk2b4ebc52ae5c3b34; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.identity_provider
    ADD CONSTRAINT fk2b4ebc52ae5c3b34 FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: client_attributes fk3c47c64beacca966; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_attributes
    ADD CONSTRAINT fk3c47c64beacca966 FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: federated_identity fk404288b92ef007a6; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.federated_identity
    ADD CONSTRAINT fk404288b92ef007a6 FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: client_node_registrations fk4129723ba992f594; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_node_registrations
    ADD CONSTRAINT fk4129723ba992f594 FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: redirect_uris fk_1burs8pb4ouj97h5wuppahv9f; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.redirect_uris
    ADD CONSTRAINT fk_1burs8pb4ouj97h5wuppahv9f FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: user_federation_provider fk_1fj32f6ptolw2qy60cd8n01e8; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_provider
    ADD CONSTRAINT fk_1fj32f6ptolw2qy60cd8n01e8 FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_required_credential fk_5hg65lybevavkqfki3kponh9v; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_required_credential
    ADD CONSTRAINT fk_5hg65lybevavkqfki3kponh9v FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: resource_attribute fk_5hrm2vlf9ql5fu022kqepovbr; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_attribute
    ADD CONSTRAINT fk_5hrm2vlf9ql5fu022kqepovbr FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: user_attribute fk_5hrm2vlf9ql5fu043kqepovbr; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_attribute
    ADD CONSTRAINT fk_5hrm2vlf9ql5fu043kqepovbr FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: user_required_action fk_6qj3w1jw9cvafhe19bwsiuvmd; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_required_action
    ADD CONSTRAINT fk_6qj3w1jw9cvafhe19bwsiuvmd FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: keycloak_role fk_6vyqfe4cn4wlq8r6kt5vdsj5c; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.keycloak_role
    ADD CONSTRAINT fk_6vyqfe4cn4wlq8r6kt5vdsj5c FOREIGN KEY (realm) REFERENCES public.realm(id);


--
-- Name: realm_smtp_config fk_70ej8xdxgxd0b9hh6180irr0o; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_smtp_config
    ADD CONSTRAINT fk_70ej8xdxgxd0b9hh6180irr0o FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_attribute fk_8shxd6l3e9atqukacxgpffptw; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_attribute
    ADD CONSTRAINT fk_8shxd6l3e9atqukacxgpffptw FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: composite_role fk_a63wvekftu8jo1pnj81e7mce2; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.composite_role
    ADD CONSTRAINT fk_a63wvekftu8jo1pnj81e7mce2 FOREIGN KEY (composite) REFERENCES public.keycloak_role(id);


--
-- Name: authentication_execution fk_auth_exec_flow; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authentication_execution
    ADD CONSTRAINT fk_auth_exec_flow FOREIGN KEY (flow_id) REFERENCES public.authentication_flow(id);


--
-- Name: authentication_execution fk_auth_exec_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authentication_execution
    ADD CONSTRAINT fk_auth_exec_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: authentication_flow fk_auth_flow_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authentication_flow
    ADD CONSTRAINT fk_auth_flow_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: authenticator_config fk_auth_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.authenticator_config
    ADD CONSTRAINT fk_auth_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: user_role_mapping fk_c4fqv34p1mbylloxang7b1q3l; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_role_mapping
    ADD CONSTRAINT fk_c4fqv34p1mbylloxang7b1q3l FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: client_scope_attributes fk_cl_scope_attr_scope; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_scope_attributes
    ADD CONSTRAINT fk_cl_scope_attr_scope FOREIGN KEY (scope_id) REFERENCES public.client_scope(id);


--
-- Name: client_scope_role_mapping fk_cl_scope_rm_scope; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_scope_role_mapping
    ADD CONSTRAINT fk_cl_scope_rm_scope FOREIGN KEY (scope_id) REFERENCES public.client_scope(id);


--
-- Name: protocol_mapper fk_cli_scope_mapper; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.protocol_mapper
    ADD CONSTRAINT fk_cli_scope_mapper FOREIGN KEY (client_scope_id) REFERENCES public.client_scope(id);


--
-- Name: client_initial_access fk_client_init_acc_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.client_initial_access
    ADD CONSTRAINT fk_client_init_acc_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: component_config fk_component_config; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.component_config
    ADD CONSTRAINT fk_component_config FOREIGN KEY (component_id) REFERENCES public.component(id);


--
-- Name: component fk_component_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.component
    ADD CONSTRAINT fk_component_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_default_groups fk_def_groups_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_default_groups
    ADD CONSTRAINT fk_def_groups_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: user_federation_mapper_config fk_fedmapper_cfg; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_mapper_config
    ADD CONSTRAINT fk_fedmapper_cfg FOREIGN KEY (user_federation_mapper_id) REFERENCES public.user_federation_mapper(id);


--
-- Name: user_federation_mapper fk_fedmapperpm_fedprv; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_mapper
    ADD CONSTRAINT fk_fedmapperpm_fedprv FOREIGN KEY (federation_provider_id) REFERENCES public.user_federation_provider(id);


--
-- Name: user_federation_mapper fk_fedmapperpm_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_mapper
    ADD CONSTRAINT fk_fedmapperpm_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: associated_policy fk_frsr5s213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.associated_policy
    ADD CONSTRAINT fk_frsr5s213xcx4wnkog82ssrfy FOREIGN KEY (associated_policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: scope_policy fk_frsrasp13xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.scope_policy
    ADD CONSTRAINT fk_frsrasp13xcx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: resource_server_perm_ticket fk_frsrho213xcx4wnkog82sspmt; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrho213xcx4wnkog82sspmt FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: resource_server_resource fk_frsrho213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_resource
    ADD CONSTRAINT fk_frsrho213xcx4wnkog82ssrfy FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: resource_server_perm_ticket fk_frsrho213xcx4wnkog83sspmt; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrho213xcx4wnkog83sspmt FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: resource_server_perm_ticket fk_frsrho213xcx4wnkog84sspmt; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrho213xcx4wnkog84sspmt FOREIGN KEY (scope_id) REFERENCES public.resource_server_scope(id);


--
-- Name: associated_policy fk_frsrpas14xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.associated_policy
    ADD CONSTRAINT fk_frsrpas14xcx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: scope_policy fk_frsrpass3xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.scope_policy
    ADD CONSTRAINT fk_frsrpass3xcx4wnkog82ssrfy FOREIGN KEY (scope_id) REFERENCES public.resource_server_scope(id);


--
-- Name: resource_server_perm_ticket fk_frsrpo2128cx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrpo2128cx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: resource_server_policy fk_frsrpo213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_policy
    ADD CONSTRAINT fk_frsrpo213xcx4wnkog82ssrfy FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: resource_scope fk_frsrpos13xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_scope
    ADD CONSTRAINT fk_frsrpos13xcx4wnkog82ssrfy FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: resource_policy fk_frsrpos53xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_policy
    ADD CONSTRAINT fk_frsrpos53xcx4wnkog82ssrfy FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: resource_policy fk_frsrpp213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_policy
    ADD CONSTRAINT fk_frsrpp213xcx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: resource_scope fk_frsrps213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_scope
    ADD CONSTRAINT fk_frsrps213xcx4wnkog82ssrfy FOREIGN KEY (scope_id) REFERENCES public.resource_server_scope(id);


--
-- Name: resource_server_scope fk_frsrso213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_server_scope
    ADD CONSTRAINT fk_frsrso213xcx4wnkog82ssrfy FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: composite_role fk_gr7thllb9lu8q4vqa4524jjy8; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.composite_role
    ADD CONSTRAINT fk_gr7thllb9lu8q4vqa4524jjy8 FOREIGN KEY (child_role) REFERENCES public.keycloak_role(id);


--
-- Name: user_consent_client_scope fk_grntcsnt_clsc_usc; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_consent_client_scope
    ADD CONSTRAINT fk_grntcsnt_clsc_usc FOREIGN KEY (user_consent_id) REFERENCES public.user_consent(id);


--
-- Name: user_consent fk_grntcsnt_user; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT fk_grntcsnt_user FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: group_attribute fk_group_attribute_group; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.group_attribute
    ADD CONSTRAINT fk_group_attribute_group FOREIGN KEY (group_id) REFERENCES public.keycloak_group(id);


--
-- Name: group_role_mapping fk_group_role_group; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.group_role_mapping
    ADD CONSTRAINT fk_group_role_group FOREIGN KEY (group_id) REFERENCES public.keycloak_group(id);


--
-- Name: realm_enabled_event_types fk_h846o4h0w8epx5nwedrf5y69j; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_enabled_event_types
    ADD CONSTRAINT fk_h846o4h0w8epx5nwedrf5y69j FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_events_listeners fk_h846o4h0w8epx5nxev9f5y69j; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_events_listeners
    ADD CONSTRAINT fk_h846o4h0w8epx5nxev9f5y69j FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: identity_provider_mapper fk_idpm_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.identity_provider_mapper
    ADD CONSTRAINT fk_idpm_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: idp_mapper_config fk_idpmconfig; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.idp_mapper_config
    ADD CONSTRAINT fk_idpmconfig FOREIGN KEY (idp_mapper_id) REFERENCES public.identity_provider_mapper(id);


--
-- Name: web_origins fk_lojpho213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.web_origins
    ADD CONSTRAINT fk_lojpho213xcx4wnkog82ssrfy FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: scope_mapping fk_ouse064plmlr732lxjcn1q5f1; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.scope_mapping
    ADD CONSTRAINT fk_ouse064plmlr732lxjcn1q5f1 FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: protocol_mapper fk_pcm_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.protocol_mapper
    ADD CONSTRAINT fk_pcm_realm FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: credential fk_pfyr0glasqyl0dei3kl69r6v0; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.credential
    ADD CONSTRAINT fk_pfyr0glasqyl0dei3kl69r6v0 FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: protocol_mapper_config fk_pmconfig; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.protocol_mapper_config
    ADD CONSTRAINT fk_pmconfig FOREIGN KEY (protocol_mapper_id) REFERENCES public.protocol_mapper(id);


--
-- Name: default_client_scope fk_r_def_cli_scope_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.default_client_scope
    ADD CONSTRAINT fk_r_def_cli_scope_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: required_action_provider fk_req_act_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.required_action_provider
    ADD CONSTRAINT fk_req_act_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: resource_uris fk_resource_server_uris; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.resource_uris
    ADD CONSTRAINT fk_resource_server_uris FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: role_attribute fk_role_attribute_id; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.role_attribute
    ADD CONSTRAINT fk_role_attribute_id FOREIGN KEY (role_id) REFERENCES public.keycloak_role(id);


--
-- Name: realm_supported_locales fk_supported_locales_realm; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.realm_supported_locales
    ADD CONSTRAINT fk_supported_locales_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: user_federation_config fk_t13hpu1j94r2ebpekr39x5eu5; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_federation_config
    ADD CONSTRAINT fk_t13hpu1j94r2ebpekr39x5eu5 FOREIGN KEY (user_federation_provider_id) REFERENCES public.user_federation_provider(id);


--
-- Name: user_group_membership fk_user_group_user; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.user_group_membership
    ADD CONSTRAINT fk_user_group_user FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: policy_config fkdc34197cf864c4e43; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.policy_config
    ADD CONSTRAINT fkdc34197cf864c4e43 FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: identity_provider_config fkdc4897cf864c4e43; Type: FK CONSTRAINT; Schema: public; Owner: keycloak
--

ALTER TABLE ONLY public.identity_provider_config
    ADD CONSTRAINT fkdc4897cf864c4e43 FOREIGN KEY (identity_provider_id) REFERENCES public.identity_provider(internal_id);


--
-- PostgreSQL database dump complete
--

\unrestrict kqpPGPOWgiDizmB4jVZnkVWbGGohgzfwQmiq91x0w1Ybhf9EURhd4gf6JP3VXaU

