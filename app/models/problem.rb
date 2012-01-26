class Problem < ActiveRecord::Base
  has_and_belongs_to_many :problem_sets
  has_many :test_cases, :dependent => :destroy
  has_many :submissions, :dependent => :destroy
  belongs_to :user

  attr_accessible :title, :statement, :input, :output, :memory_limit, :time_limit, :evaluator

  # Scopes
  scope :distinct, select("distinct(problems.id), problems.*")

  #scope :visible, lambda { joins(:problem_sets => :groups => :users).where( :users => { :id => current_user.id } ).select("distinct(problems.id), problems.*") }
  def self.score_by_user(user_id)
    select("(SELECT MAX(submissions.score) FROM submissions WHERE submissions.problem_id = problems.id AND user_id = #{user_id.to_i}) AS score")
  end
  def self.by_group(group_id)
    joins(:problem_sets => :groups).where(:groups => {:id => group_id}).distinct
  end

  # methods

  def get_highest_scoring_submission(user, from = DateTime.new(1), to = DateTime.now)
    subs = self.submissions.find(:all, :conditions => ["created_at between ? and ? and user_id = ?", from, to, user])
    return subs.max_by {|s| s.score}
  end

  def get_score(user, from = DateTime.new(1), to = DateTime.now)
    subs = self.submissions.find(:all, :limit => 1, :order => "score DESC", :conditions => ["created_at between ? and ? and user_id = ?", from, to, user])
    scores = subs.map {|s| s.score}
    return scores.max 
  end

  def submission_history(user, from = DateTime.new(1), to = DateTime.now)
    return Submission.find(:all, :conditions => ["created_at between ? and ? and user_id IN (?) and problem_id = ?", from, to, user, self], :order => "created_at DESC")
  end

  def can_be_viewed_by(user)
    if user.is_admin
      return true
    end

    if user == self.user
      return true
    end

    #might be painfully slow?
    self.problem_sets.each do |problem_set|
      if problem_set.contest && problem_set.contest.has_current_competitor(user)
        return true
      end
    end
    
    user.contests.each do |contest|
      if contest.is_running?
        return false
      end
    end

    user.groups.each do |g|
      if (self.problem_sets & g.problem_sets).any?
        return true
      end
    end

    return false
  end

end
