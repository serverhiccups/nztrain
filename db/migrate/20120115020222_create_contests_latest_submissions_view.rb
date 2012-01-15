class CreateContestsLatestSubmissionsView < ActiveRecord::Migration
  def self.up
    execute "CREATE VIEW contests_latest_submissions AS SELECT DISTINCT ON (contests.id, submissions.user_id, submissions.problem_id) submissions.id, submissions.score as score, submissions.user_id, submissions.problem_id, submissions.created_at, submissions.updated_at, contest_relations.contest_id FROM contests JOIN contest_relations ON contests.id = contest_relations.contest_id JOIN contests_problems ON contests_problems.contest_id = contests.id JOIN submissions ON contest_relations.user_id = submissions.user_id AND submissions.problem_id = contests_problems.problem_id WHERE submissions.created_at BETWEEN contests.start_time AND contests.end_time ORDER BY contests.id, submissions.user_id, submissions.problem_id, created_at DESC;"
  end

  def self.down
    execute "DROP VIEW contests_latest_submissions"
  end
end
