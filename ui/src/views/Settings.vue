<!--
  Copyright (C) 2022 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.kutt_fqdn')"
              :helper-text="$t('settings.kutt_fqdn_helper')"
              placeholder="kutt.example.org"
              v-model.trim="host"
              class="mg-bottom"
              :invalid-message="$t(error.host)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="host"
            >
            </cv-text-input>
            <NsToggle
              value="letsEncrypt"
              :label="core.$t('apps_lets_encrypt.request_https_certificate')"
              v-model="isLetsEncryptEnabled"
              :disabled="stillLoading"
              class="mg-bottom"
            >
              <template #tooltip>
                <div class="mg-bottom-sm">
                  {{ core.$t("apps_lets_encrypt.lets_encrypt_tips") }}
                </div>
                <div class="mg-bottom-sm">
                  <cv-link @click="goToCertificates">
                    {{ core.$t("apps_lets_encrypt.go_to_tls_certificates") }}
                  </cv-link>
                </div>
              </template>
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <cv-row
              v-if="isLetsEncryptCurrentlyEnabled && !isLetsEncryptEnabled"
            >
              <cv-column>
                <NsInlineNotification
                  kind="warning"
                  :title="
                    core.$t('apps_lets_encrypt.lets_encrypt_disabled_warning')
                  "
                  :description="
                    core.$t(
                      'apps_lets_encrypt.lets_encrypt_disabled_warning_description',
                      {
                        node: this.status.node_ui_name
                          ? this.status.node_ui_name
                          : this.status.node,
                      }
                    )
                  "
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <cv-toggle
              value="httpToHttps"
              :label="$t('settings.http_to_https')"
              v-model="isHttpToHttpsEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <!-- Kutt settings, see https://github.com/thedevs-network/kutt/blob/main/.example.env -->
            <cv-accordion ref="accordion" class="maxwidth mg-bottom">
              <cv-accordion-item :open="toggleAccordion[0]">
                <template slot="title">{{
                  $t("settings.section_links")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.site_name')"
                    :helper-text="$t('settings.site_name_helper')"
                    v-model.trim="siteName"
                    :invalid-message="error.site_name"
                    :disabled="stillLoading"
                    ref="site_name"
                    class="mg-bottom"
                  />
                  <cv-text-input
                    :label="$t('settings.link_length')"
                    :helper-text="$t('settings.link_length_helper')"
                    v-model.trim="linkLength"
                    :invalid-message="error.link_length"
                    :disabled="stillLoading"
                    ref="link_length"
                    type="number"
                    class="mg-bottom"
                  />
                  <cv-text-input
                    :label="$t('settings.link_custom_alphabet')"
                    :helper-text="$t('settings.link_custom_alphabet_helper')"
                    v-model.trim="linkCustomAlphabet"
                    :invalid-message="error.link_custom_alphabet"
                    :disabled="stillLoading"
                    ref="link_custom_alphabet"
                    class="mg-bottom"
                  />
                </template>
              </cv-accordion-item>
              <cv-accordion-item :open="toggleAccordion[1]">
                <template slot="title">{{
                  $t("settings.section_access")
                }}</template>
                <template slot="content">
                  <cv-toggle
                    value="disallow_registration"
                    :label="$t('settings.disallow_registration')"
                    v-model="disallowRegistration"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.disallow_registration_helper") }}
                  </p>
                  <cv-toggle
                    value="disallow_anonymous_links"
                    :label="$t('settings.disallow_anonymous_links')"
                    v-model="disallowAnonymousLinks"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.disallow_anonymous_links_helper") }}
                  </p>
                  <cv-toggle
                    value="disallow_login_form"
                    :label="$t('settings.disallow_login_form')"
                    v-model="disallowLoginForm"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.disallow_login_form_helper") }}
                  </p>
                  <NsInlineNotification
                    v-if="error.disallow_login_form"
                    kind="error"
                    :title="error.disallow_login_form"
                    :showCloseButton="false"
                  />
                  <cv-toggle
                    value="enable_rate_limit"
                    :label="$t('settings.enable_rate_limit')"
                    v-model="enableRateLimit"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.enable_rate_limit_helper") }}
                  </p>
                </template>
              </cv-accordion-item>
              <cv-accordion-item :open="toggleAccordion[2]">
                <template slot="title">{{
                  $t("settings.section_custom_domains")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.server_ip_address')"
                    :helper-text="$t('settings.server_ip_address_helper')"
                    v-model.trim="serverIpAddress"
                    :invalid-message="error.server_ip_address"
                    :disabled="stillLoading"
                    ref="server_ip_address"
                    class="mg-bottom"
                  />
                  <cv-text-input
                    :label="$t('settings.server_cname_address')"
                    :helper-text="$t('settings.server_cname_address_helper')"
                    v-model.trim="serverCnameAddress"
                    :invalid-message="error.server_cname_address"
                    :disabled="stillLoading"
                    ref="server_cname_address"
                    class="mg-bottom"
                  />
                  <cv-toggle
                    value="custom_domain_use_https"
                    :label="$t('settings.custom_domain_use_https')"
                    v-model="customDomainUseHttps"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.custom_domain_use_https_helper") }}
                  </p>
                </template>
              </cv-accordion-item>
              <cv-accordion-item :open="toggleAccordion[3]">
                <template slot="title">{{
                  $t("settings.section_contact_mail")
                }}</template>
                <template slot="content">
                  <NsInlineNotification
                    :kind="mailEnabled ? 'info' : 'warning'"
                    :title="
                      $t(mailEnabled ? 'settings.mail_on' : 'settings.mail_off')
                    "
                    :description="
                      $t(
                        mailEnabled
                          ? 'settings.mail_on_description'
                          : 'settings.mail_off_description'
                      )
                    "
                    :showCloseButton="false"
                  />
                  <cv-text-input
                    :label="$t('settings.mail_from')"
                    :helper-text="$t('settings.mail_from_helper')"
                    :placeholder="mailFromPlaceholder"
                    v-model.trim="mailFrom"
                    :invalid-message="error.mail_from"
                    :disabled="stillLoading"
                    ref="mail_from"
                    class="mg-bottom"
                  />
                  <cv-text-input
                    :label="$t('settings.report_email')"
                    :helper-text="$t('settings.report_email_helper')"
                    v-model.trim="reportEmail"
                    :invalid-message="error.report_email"
                    :disabled="stillLoading"
                    ref="report_email"
                    class="mg-bottom"
                  />
                  <cv-text-input
                    :label="$t('settings.contact_email')"
                    :helper-text="$t('settings.contact_email_helper')"
                    v-model.trim="contactEmail"
                    :invalid-message="error.contact_email"
                    :disabled="stillLoading"
                    ref="contact_email"
                    class="mg-bottom"
                  />
                </template>
              </cv-accordion-item>
              <cv-accordion-item :open="toggleAccordion[4]">
                <template slot="title">{{
                  $t("settings.section_oidc")
                }}</template>
                <template slot="content">
                  <cv-toggle
                    value="oidc_enabled"
                    :label="$t('settings.oidc_enabled')"
                    v-model="oidcEnabled"
                    :disabled="stillLoading"
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <p class="helper mg-bottom">
                    {{ $t("settings.oidc_enabled_helper") }}
                  </p>
                  <template v-if="oidcEnabled">
                    <cv-text-input
                      :label="$t('settings.oidc_issuer')"
                      :helper-text="$t('settings.oidc_issuer_helper')"
                      :placeholder="'https://sso.example.org/realms/main'"
                      v-model.trim="oidcIssuer"
                      :invalid-message="error.oidc_issuer"
                      :disabled="stillLoading"
                      ref="oidc_issuer"
                      class="mg-bottom"
                    />
                    <cv-text-input
                      :label="$t('settings.oidc_client_id')"
                      :helper-text="$t('settings.oidc_client_id_helper')"
                      v-model.trim="oidcClientId"
                      :invalid-message="error.oidc_client_id"
                      :disabled="stillLoading"
                      ref="oidc_client_id"
                      class="mg-bottom"
                    />
                    <cv-text-input
                      :label="$t('settings.oidc_client_secret')"
                      :helper-text="
                        oidcClientSecretSet
                          ? $t('settings.oidc_client_secret_keep')
                          : $t('settings.oidc_client_secret_helper')
                      "
                      type="password"
                      :password-hide-label="$t('settings.hide')"
                      :password-show-label="$t('settings.show')"
                      v-model="oidcClientSecret"
                      :invalid-message="error.oidc_client_secret"
                      :disabled="stillLoading"
                      autocomplete="new-password"
                      ref="oidc_client_secret"
                      class="mg-bottom"
                    />
                    <cv-text-input
                      :label="$t('settings.oidc_scope')"
                      :helper-text="$t('settings.oidc_scope_helper')"
                      v-model.trim="oidcScope"
                      :invalid-message="error.oidc_scope"
                      :disabled="stillLoading"
                      ref="oidc_scope"
                      class="mg-bottom"
                    />
                    <cv-text-input
                      :label="$t('settings.oidc_email_claim')"
                      :helper-text="$t('settings.oidc_email_claim_helper')"
                      v-model.trim="oidcEmailClaim"
                      :invalid-message="error.oidc_email_claim"
                      :disabled="stillLoading"
                      ref="oidc_email_claim"
                      class="mg-bottom"
                    />
                    <cv-text-input
                      :label="$t('settings.oidc_prompt')"
                      :helper-text="$t('settings.oidc_prompt_helper')"
                      v-model.trim="oidcPrompt"
                      :invalid-message="error.oidc_prompt"
                      :disabled="stillLoading"
                      ref="oidc_prompt"
                      class="mg-bottom"
                    />
                    <cv-text-input
                      :label="$t('settings.oidc_button_text')"
                      :helper-text="$t('settings.oidc_button_text_helper')"
                      v-model.trim="oidcButtonText"
                      :invalid-message="error.oidc_button_text"
                      :disabled="stillLoading"
                      ref="oidc_button_text"
                      class="mg-bottom"
                    />
                  </template>
                </template>
              </cv-accordion-item>
            </cv-accordion>
            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <cv-row v-if="error.getStatus">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.get-status')"
                  :description="error.getStatus"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <cv-row v-if="validationErrorDetails.length">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="
                    core.$t('apps_lets_encrypt.cannot_obtain_certificate')
                  "
                  :showCloseButton="false"
                >
                  <template #description>
                    <div class="flex flex-col gap-2">
                      <div
                        v-for="(detail, index) in validationErrorDetails"
                        :key="index"
                      >
                        {{ detail }}
                      </div>
                    </div>
                  </template>
                </NsInlineNotification>
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      status: {},
      validationErrorDetails: [],
      urlCheckInterval: null,
      host: "",
      isLetsEncryptEnabled: false,
      isLetsEncryptCurrentlyEnabled: false,
      isHttpToHttpsEnabled: true,
      toggleAccordion: [true, false, false, false, false],
      siteName: "Kutt",
      linkLength: "6",
      linkCustomAlphabet: "",
      disallowRegistration: true,
      disallowAnonymousLinks: true,
      disallowLoginForm: false,
      enableRateLimit: false,
      serverIpAddress: "",
      serverCnameAddress: "",
      customDomainUseHttps: false,
      mailEnabled: false,
      mailFrom: "",
      reportEmail: "",
      contactEmail: "",
      oidcEnabled: false,
      oidcIssuer: "",
      oidcClientId: "",
      oidcClientSecret: "",
      oidcClientSecretSet: false,
      oidcScope: "",
      oidcEmailClaim: "",
      oidcPrompt: "",
      oidcButtonText: "",
      loading: {
        getConfiguration: false,
        configureModule: false,
        getStatus: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        http2https: "",
        site_name: "",
        link_length: "",
        link_custom_alphabet: "",
        server_ip_address: "",
        server_cname_address: "",
        mail_from: "",
        report_email: "",
        contact_email: "",
        oidc_issuer: "",
        oidc_client_id: "",
        oidc_client_secret: "",
        oidc_scope: "",
        oidc_email_claim: "",
        oidc_prompt: "",
        oidc_button_text: "",
        disallow_login_form: "",
        getStatus: false,
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    mailFromPlaceholder() {
      return `${this.siteName || "Kutt"} <noreply@${
        this.host || "kutt.example.org"
      }>`;
    },
    stillLoading() {
      return (
        this.loading.getConfiguration ||
        this.loading.configureModule ||
        this.loading.getStatus
      );
    },
  },
  created() {
    this.getConfiguration();
    this.getStatus();
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  methods: {
    openSectionOf(param) {
      const sections = [
        ["site_name", "link_length", "link_custom_alphabet"],
        [
          "disallow_registration",
          "disallow_anonymous_links",
          "disallow_login_form",
          "enable_rate_limit",
        ],
        [
          "server_ip_address",
          "server_cname_address",
          "custom_domain_use_https",
        ],
        ["mail_from", "report_email", "contact_email"],
        [],
      ];
      const index = sections.findIndex((fields) => fields.includes(param));
      const open = [false, false, false, false, false];
      open[index >= 0 ? index : param.startsWith("oidc_") ? 4 : 0] = true;
      this.toggleAccordion = open;
    },
    goToCertificates() {
      this.core.$router.push("/settings/tls-certificates");
    },
    async getStatus() {
      this.loading.getStatus = true;
      this.error.getStatus = "";
      const taskAction = "get-status";
      const eventId = this.getUuid();
      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getStatusAborted
      );
      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getStatusCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];
      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getStatus = this.getErrorMessage(err);
        this.loading.getStatus = false;
        return;
      }
    },
    getStatusAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getStatus = this.$t("error.generic_error");
      this.loading.getStatus = false;
    },
    getStatusCompleted(taskContext, taskResult) {
      this.status = taskResult.output;
      this.loading.getStatus = false;
    },
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.host = config.host;
      this.isLetsEncryptEnabled = config.lets_encrypt;
      this.isLetsEncryptCurrentlyEnabled = config.lets_encrypt;
      this.isHttpToHttpsEnabled = config.http2https;
      this.siteName = config.site_name;
      this.linkLength = String(config.link_length);
      this.linkCustomAlphabet = config.link_custom_alphabet;
      this.disallowRegistration = config.disallow_registration;
      this.disallowAnonymousLinks = config.disallow_anonymous_links;
      this.disallowLoginForm = config.disallow_login_form;
      this.enableRateLimit = config.enable_rate_limit;
      this.serverIpAddress = config.server_ip_address;
      this.serverCnameAddress = config.server_cname_address;
      this.customDomainUseHttps = config.custom_domain_use_https;
      this.mailEnabled = config.mail_enabled;
      this.mailFrom = config.mail_from;
      this.reportEmail = config.report_email;
      this.contactEmail = config.contact_email;
      this.oidcEnabled = config.oidc_enabled;
      this.oidcIssuer = config.oidc_issuer;
      this.oidcClientId = config.oidc_client_id;
      this.oidcClientSecret = "";
      this.oidcClientSecretSet = config.oidc_client_secret_set;
      this.oidcScope = config.oidc_scope;
      this.oidcEmailClaim = config.oidc_email_claim;
      this.oidcPrompt = config.oidc_prompt;
      this.oidcButtonText = config.oidc_button_text;

      this.loading.getConfiguration = false;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      this.validationErrorDetails = [];

      let isValidationOk = true;
      if (!this.host) {
        this.error.host = "common.required";

        if (isValidationOk) {
          this.focusElement("host");
        }
        isValidationOk = false;
      }
      const length = Number(this.linkLength);
      if (!Number.isInteger(length) || length < 3 || length > 32) {
        this.error.link_length = this.$t("settings.link_length_invalid");
        if (isValidationOk) {
          this.toggleAccordion = [true, false, false, false, false];
          this.focusElement("link_length");
        }
        isValidationOk = false;
      }
      if (this.oidcEnabled) {
        for (const [field, value] of [
          ["oidc_issuer", this.oidcIssuer],
          ["oidc_client_id", this.oidcClientId],
        ]) {
          if (!value) {
            this.error[field] = this.$t("common.required");
            isValidationOk = false;
          }
        }
        if (!this.oidcClientSecret && !this.oidcClientSecretSet) {
          this.error.oidc_client_secret = this.$t("common.required");
          isValidationOk = false;
        }
      }
      if (this.disallowLoginForm && !this.oidcEnabled) {
        this.error.disallow_login_form = this.$t(
          "settings.login_form_needs_oidc"
        );
        isValidationOk = false;
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;
      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        if (validationError.details) {
          // show inline error notification with details
          this.validationErrorDetails = validationError.details
            .split("\n")
            .filter((detail) => detail.trim() !== "");
        } else {
          // set i18n error message
          this.error[param] = this.$t("settings." + validationError.error);
          this.openSectionOf(param);
          if (!focusAlreadySet) {
            this.focusElement(param);
            focusAlreadySet = true;
          }
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.isLetsEncryptEnabled,
            http2https: this.isHttpToHttpsEnabled,
            site_name: this.siteName,
            link_length: Number(this.linkLength),
            link_custom_alphabet: this.linkCustomAlphabet,
            disallow_registration: this.disallowRegistration,
            disallow_anonymous_links: this.disallowAnonymousLinks,
            disallow_login_form: this.disallowLoginForm,
            enable_rate_limit: this.enableRateLimit,
            server_ip_address: this.serverIpAddress,
            server_cname_address: this.serverCnameAddress,
            custom_domain_use_https: this.customDomainUseHttps,
            mail_from: this.mailFrom,
            report_email: this.reportEmail,
            contact_email: this.contactEmail,
            oidc_enabled: this.oidcEnabled,
            oidc_issuer: this.oidcIssuer,
            oidc_client_id: this.oidcClientId,
            // empty: keep the saved secret
            oidc_client_secret: this.oidcClientSecret,
            oidc_scope: this.oidcScope,
            oidc_email_claim: this.oidcEmailClaim,
            oidc_prompt: this.oidcPrompt,
            oidc_button_text: this.oidcButtonText,
          },
          extra: {
            title: this.$t("settings.instance_configuration", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.configuring"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.mg-bottom {
  margin-bottom: $spacing-06;
}

.maxwidth {
  max-width: 38rem;
}

.helper {
  margin-top: -$spacing-05;
  font-size: 0.75rem;
  color: $ui-04;
}
</style>
