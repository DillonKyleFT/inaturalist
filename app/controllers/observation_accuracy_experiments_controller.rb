# frozen_string_literal: true

class ObservationAccuracyExperimentsController < ApplicationController
  before_action :load_experiment, only: [:show, :get_more_validators, :get_methods_data, :get_results_data]

  layout "bootstrap"

  helper_method :get_rank_and_parent

  def get_rank_and_parent( rank_level )
    return [""] if rank_level.nil?

    ranks = Taxon::RANK_FOR_RANK_LEVEL
    case rank_level
    when 5, 10, 100
      ranks[rank_level]
    else
      matching_rank = ranks.keys.find {| k | k <= rank_level }
      child_rank = ranks[matching_rank - 10]
      [child_rank, ranks[matching_rank]].join( "_" )
    end
  end

  def get_more_validators
    @more_validators = @experiment.get_validator_names( limit: nil, offset: 20 )
    respond_to do | format |
      format.html { render partial: "additional_validators", locals: { validators: @more_validators } }
    end
  end

  def get_methods_data
    @candidate_validators, @mean_validator_count, @mean_sample_count = @experiment.get_assignment_methods
    @mean_validators_per_sample, @validators_per_sample, @validators_per_sample_ylim = @experiment.get_val_methods
    respond_to do | format |
      format.html do
        render partial: "methods", locals: {
          candidate_validators: @candidate_validators,
          mean_sample_count: @mean_sample_count,
          mean_validator_count: @mean_validator_count
        }
      end
    end
  end

  def get_results_data
    tab = params[:tab]
    @stats, @data, @precision_data, @ylims = @experiment.get_results_data( tab )

    respond_to do | format |
      format.html do
        render partial: "results", locals: {
          stats: @stats,
          data: @data,
          precision_data: @precision_data,
          ylims: @ylims
        }
      end
    end
  end

  def show
    @explorable = ( @experiment.validator_deadline_date < Time.now ) ||
      ( logged_in? && current_user.is_admin? )

    @validators = @experiment.get_validator_names( limit: 20, offset: 0 )
    @tab = params[:tab] || "research_grade_results"
    valid_tabs = %w(research_grade_results verifiable_results all_results methods)
    @tab = "research_grade_results" unless valid_tabs.include?( @tab )
    render "show"
  end

  private

  def load_experiment
    render_404 unless ( @experiment = ObservationAccuracyExperiment.find_by_id( params[:id] ) )
  end
end
