# typed: true
# frozen_string_literal: true
########################################################################
# HasLifecycle provides methods to enable lifecycle hooks
########################################################################
module HasLifecycle
  def self.included(base)
    base.extend(ClassMethods)
  end

  # ClassMethods
  module ClassMethods
    extend T::Sig

    sig { returns(Hash) }
    def _init_validation_hash
      {
        after: {},
        before: {}
      }
    end

    sig { params(stage: T.any(String, Symbol), step: T.any(Symbol, String)).returns(Array) }
    def lifecycle_actions(stage, step)
      all = []
      # inherit lifecycle_actions
      sclazz = self.superclass
      all.concat(sclazz.lifecycle_actions(stage, step)) if sclazz.respond_to?(:lifecycle_actions)

      # Add this lifecycle actions
      la_exists = @_actions && @_actions[stage] && @_actions[stage][step]
      all.concat(@_actions[stage][step]) if la_exists
      all
    end

    sig { params(lifecycle_step: Symbol, method_name_or_proc: T.any(String, Symbol, T.proc.returns(T::Boolean))).void }
    # Currently only supporting after(:initialize)
    def after(lifecycle_step, method_name_or_proc)
      @_actions = _init_validation_hash unless @_actions
      @_actions[:after][lifecycle_step] = [] unless @_actions[:after][lifecycle_step]
      @_actions[:after][lifecycle_step] << method_name_or_proc
    end

    sig { params(lifecycle_step: Symbol, method_name_or_proc: T.any(String, Symbol, T.proc.returns(T::Boolean))).void }
    def before(lifecycle_step, method_name_or_proc)
      @_actions = _init_validation_hash unless @_actions
      @_actions[:before][lifecycle_step] = [] unless @_actions[:before][lifecycle_step]
      @_actions[:before][lifecycle_step] << method_name_or_proc
    end
  end

  # This method will return a list of errors if not valid, or nil
  def execute_lifecycle(stage, step)
    self.class.lifecycle_actions(stage, step).each do |actions|
      if actions.is_a? Proc
        self.instance_exec(&actions)
      else
        self.send(actions)
      end
    end
  end
end
