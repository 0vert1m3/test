<script>
  import pipelineStage from '../../pipelines/components/stage.vue';
  import ciIcon from '../../vue_shared/components/ci_icon.vue';
  import icon from '../../vue_shared/components/icon.vue';
  import linkedPipelinesMiniList from '../../vue_shared/components/linked_pipelines_mini_list.vue';

  export default {
    name: 'MRWidgetPipeline',
    props: {
      pipeline: {
        type: Object,
        required: true,
      },
      // This prop needs to be camelCase, html attributes are case insensive
      // https://vuejs.org/v2/guide/components.html#camelCase-vs-kebab-case
      hasCi: {
        type: Boolean,
        required: false,
      },
      ciStatus: {
        type: String,
        required: false,
      },
    },
    components: {
      pipelineStage,
      ciIcon,
      icon,
      linkedPipelinesMiniList,
    },
    computed: {
      hasPipeline() {
        return this.pipeline && Object.keys(this.pipeline).length > 0;
      },
      hasCIError() {
        return this.hasCi && !this.ciStatus;
      },
      status() {
        return this.pipeline.details &&
          this.pipeline.details.status ? this.pipeline.details.status : {};
      },
      hasStages() {
        return this.pipeline.details &&
          this.pipeline.details.stages &&
          this.pipeline.details.stages.length;
      },

      /* We typically set defaults ([]) in the store or prop declarations, but because triggered
      * and triggeredBy are appended to `pipeline`, we can't set defaults in the store, and we
      * need to check their length here to prevent initializing linked-pipeline-mini-lists
      * unneccessarily. */
      triggered() {
        return this.pipeline.triggered || [];
      },
      triggeredBy() {
        const response = this.pipeline.triggered_by;
        return response ? [response] : [];
      },
    },
  };
</script>
<template>
  <div
    v-if="hasPipeline || hasCIError"
    class="mr-widget-heading">
    <div class="ci-widget media">
      <template v-if="hasCIError">
        <div class="ci-status-icon ci-status-icon-failed ci-error js-ci-error append-right-10">
          <icon name="status_failed" />
        </div>
        <div class="media-body">
          Could not connect to the CI server. Please check your settings and try again
        </div>
      </template>
      <template v-else-if="hasPipeline">
        <a
          class="append-right-10"
          :href="this.status.details_path">
          <ci-icon :status="status" />
        </a>
        <div class="media-body">
          Pipeline
          <a
            :href="pipeline.path"
            class="pipeline-id">
            #{{pipeline.id}}
          </a>

          {{pipeline.details.status.label}} for

          <a
            :href="pipeline.commit.commit_path"
            class="commit-sha js-commit-link">
            {{pipeline.commit.short_id}}</a>.

          <span class="mr-widget-pipeline-graph">
            <span class="stage-cell">
              <linked-pipelines-mini-list
                v-if="triggeredBy.length"
                :triggered-by="triggeredBy"
                />

              <div
                v-if="hasStages"
                v-for="(stage, i) in pipeline.details.stages"
                :key="i"
                class="stage-container dropdown js-mini-pipeline-graph"
                :class="{
                  'has-downstream': i === pipeline.details.stages.length - 1 && triggered.length
                }">
                <pipeline-stage :stage="stage" />
              </div>

              <linked-pipelines-mini-list
                v-if="triggered.length"
                :triggered="triggered"
                />
            </span>
          </span>

          <template v-if="pipeline.coverage">
            Coverage {{pipeline.coverage}}%
          </template>

        </div>
      </template>
    </div>
  </div>
</template>