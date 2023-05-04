# frozen_string_literal: true

class Api::V1::Peers::SearchController < Api::BaseController
  before_action :require_enabled_api!
  before_action :set_domains

  skip_before_action :require_authenticated_user!, unless: :whitelist_mode?
  skip_around_action :set_locale

  vary_by ''

  def index
    cache_even_if_authenticated!
    render json: @domains
  end

  private

  def require_enabled_api!
    head 404 unless Setting.peers_api_enabled && Chewy.enabled? && !whitelist_mode?
  end

  def set_domains
    return if params[:q].blank?

    @domains = InstancesIndex.query(function_score: {
      query: {
        prefix: {
          domain: params[:q],
        },
      },

      field_value_factor: {
        field: 'accounts_count',
        modifier: 'log2p',
      },
    }).limit(10).pluck(:domain)
  end
end
