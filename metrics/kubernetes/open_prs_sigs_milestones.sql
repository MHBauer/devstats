create temp table issues as
select i.id as issue_id,
  i.event_id,
  i.milestone_id,
  i.dup_repo_name as repo
from
  gha_issues i
where
  i.is_pull_request = true
  and i.id > 0
  and i.event_id > 0
  and i.closed_at is null
  and i.created_at < '{{to}}'
  and i.event_id = (
    select inn.event_id
    from
      gha_issues inn
    where
      inn.id = i.id
      and inn.id > 0
      and inn.event_id > 0
      and inn.created_at < '{{to}}'
      and inn.is_pull_request = true
      and inn.updated_at < '{{to}}'
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
;

create temp table prs as
select i.issue_id,
  i.event_id,
  i.milestone_id,
  i.repo
from
  issues i,
  gha_issues_pull_requests ipr,
  gha_pull_requests pr
where
  ipr.issue_id = i.issue_id
  and ipr.pull_request_id = pr.id
  and pr.id > 0
  and pr.event_id > 0
  and pr.closed_at is null
  and pr.merged_at is null
  and pr.created_at < '{{to}}'
  and pr.event_id = (
    select inn.event_id
    from
      gha_pull_requests inn
    where
      inn.id = pr.id
      and inn.id > 0
      and inn.event_id > 0
      and inn.created_at < '{{to}}'
      and inn.updated_at < '{{to}}'
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
;

create temp table prs_sigs as
select pr.issue_id,
  pr.repo,
  lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
from
  prs pr,
  gha_issues_labels il
where
  pr.event_id = il.event_id
  and pr.issue_id = il.issue_id
  and lower(substring(il.dup_label_name from '(?i)sig/(.*)')) is not null
;

create temp table prs_milestones as
select pr.issue_id,
  pr.repo,
  ml.title as milestone
from
  prs pr,
  gha_milestones ml
where
  pr.milestone_id = ml.id
  and pr.event_id = ml.event_id
;

select 
  sub.sig_milestone,
  sub.cnt
from (
  select concat('open_prs_sigs_milestones,', s.sig, '-', m.milestone, '-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_milestones m,
    prs_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone,
    s.repo
  union select concat('open_prs_sigs_milestones,', 'All-', m.milestone, '-', m.repo) as sig_milestone,
    count(m.issue_id) as cnt
  from
    prs_milestones m
  group by
    m.milestone,
    m.repo
  union select concat('open_prs_sigs_milestones,', s.sig, '-All-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_sigs s
  group by
    s.sig,
    s.repo
  union select concat('open_prs_sigs_milestones,All-All-', pr.repo) as sig_milestone,
    count(pr.issue_id) as cnt
  from
    prs pr
  group by
    pr.repo
  union select concat('open_prs_sigs_milestones,', s.sig, '-', m.milestone, '-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_milestones m,
    prs_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone
  union select concat('open_prs_sigs_milestones,', 'All-', m.milestone, '-All') as sig_milestone,
    count(m.issue_id) as cnt
  from
    prs_milestones m
  group by
    m.milestone
  union select concat('open_prs_sigs_milestones,', s.sig, '-All-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_sigs s
  group by
    s.sig
  union select 'open_prs_sigs_milestones,All-All-All' as sig_milestone,
    count(pr.issue_id) as cnt
  from
    prs pr
  ) sub
order by
  sub.cnt desc,
  sub.sig_milestone asc
;

drop table prs_milestones;
drop table prs_sigs;
drop table prs;
drop table issues;
