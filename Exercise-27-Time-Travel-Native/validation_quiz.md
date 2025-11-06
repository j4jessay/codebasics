# Exercise 27: Time Travel & Zero-Copy Cloning - Validation Quiz

## Instructions

Answer these questions after completing the exercise to test your understanding.

---

## Section 1: Time Travel Basics (10 questions)

1. What is Snowflake Time Travel?
   - [ ] A. A feature to schedule queries to run in the future
   - [ ] B. A feature to query data as it existed in the past
   - [ ] C. A backup and restore mechanism
   - [ ] D. A data migration tool

2. What is the default Time Travel retention period for Standard Edition?
   - [ ] A. 1 hour
   - [ ] B. 1 day
   - [ ] C. 7 days
   - [ ] D. 90 days

3. What SQL clause queries data at a specific timestamp?
   - [ ] A. AT(TIMESTAMP => ...)
   - [ ] B. WHEN(TIME => ...)
   - [ ] C. AS OF(...)
   - [ ] D. HISTORICAL(...)

4. What's the difference between AT and BEFORE clauses?
   - [ ] A. No difference, they're aliases
   - [ ] B. AT uses timestamps, BEFORE uses query IDs
   - [ ] C. AT is for tables, BEFORE is for schemas
   - [ ] D. AT is Standard Edition, BEFORE is Enterprise only

5. Can you use Time Travel on a table immediately after creating it?
   - [ ] A. Yes, always
   - [ ] B. No, you need to wait for history to establish
   - [ ] C. Only on Enterprise Edition
   - [ ] D. Only if you enable it manually

6. What happens to deleted data during the retention period?
   - [ ] A. It's completely removed from storage
   - [ ] B. It's archived to cheaper storage
   - [ ] C. It's maintained and accessible via Time Travel
   - [ ] D. It's moved to Fail-safe storage

7. How do you recover deleted records using Time Travel?
   - [ ] A. UNDELETE command
   - [ ] B. RESTORE FROM TIMETRAVEL command
   - [ ] C. INSERT INTO ... SELECT with AT/BEFORE clause
   - [ ] D. Contact Snowflake support

8. What is Fail-safe?
   - [ ] A. Same as Time Travel
   - [ ] B. Additional 7-day protection after Time Travel expires
   - [ ] C. A feature to prevent accidental deletions
   - [ ] D. Automatic backups to S3

9. Can you modify data in Time Travel history?
   - [ ] A. Yes, with special permissions
   - [ ] B. No, it's read-only
   - [ ] C. Yes, using UPDATE ... AT clause
   - [ ] D. Only administrators can

10. What's the maximum Time Travel retention in Enterprise Edition?
    - [ ] A. 7 days
    - [ ] B. 30 days
    - [ ] C. 90 days
    - [ ] D. 365 days

---

## Section 2: Zero-Copy Cloning (10 questions)

11. What is zero-copy cloning?
    - [ ] A. Creating a table copy with no data
    - [ ] B. Creating an instant copy that initially shares data files
    - [ ] C. Creating a view instead of a table
    - [ ] D. Copying only table structure, not data

12. What is copy-on-write?
    - [ ] A. Copying data when reading it
    - [ ] B. Copying only changed data when modifying a clone
    - [ ] C. Copying data to write-optimized storage
    - [ ] D. A type of backup strategy

13. What's the initial storage cost of a clone?
    - [ ] A. Same as the original table
    - [ ] B. 50% of the original table
    - [ ] C. Zero (no additional cost initially)
    - [ ] D. Depends on table size

14. If you modify a clone, does the original table change?
    - [ ] A. Yes, they're linked
    - [ ] B. No, they're independent after cloning
    - [ ] C. Only if you use UPDATE BOTH command
    - [ ] D. Depends on the clone type

15. What SQL command creates a zero-copy clone?
    - [ ] A. COPY TABLE original TO clone
    - [ ] B. CREATE TABLE clone CLONE original
    - [ ] C. DUPLICATE TABLE original AS clone
    - [ ] D. SELECT * INTO clone FROM original

16. Can you clone a schema?
    - [ ] A. No, only tables
    - [ ] B. Yes, including all tables and objects
    - [ ] C. Only in Enterprise Edition
    - [ ] D. Only empty schemas

17. What happens to storage cost when you modify a cloned table?
    - [ ] A. Nothing changes
    - [ ] B. Entire table is duplicated (full cost)
    - [ ] C. Only modified micro-partitions consume storage
    - [ ] D. Original table storage doubles

18. Can you clone a database?
    - [ ] A. No, only tables and schemas
    - [ ] B. Yes, entire database with all objects
    - [ ] C. Only databases smaller than 1TB
    - [ ] D. Requires special permissions

19. What's a common use case for zero-copy cloning?
    - [ ] A. Production backups
    - [ ] B. Instant test/dev environments
    - [ ] C. Data migration
    - [ ] D. Performance optimization

20. If you clone a table at 10 AM, does the clone get updates made at 11 AM?
    - [ ] A. Yes, clones stay in sync
    - [ ] B. No, clones are point-in-time snapshots
    - [ ] C. Only if you enable sync mode
    - [ ] D. Depends on table size

---

## Section 3: Practical Scenarios (10 questions)

21. A user accidentally deletes 1,000 customers. Time Travel retention is 1 day. It's been 2 days. Can you recover?
    - [ ] A. Yes, using Time Travel
    - [ ] B. No, outside retention period
    - [ ] C. Yes, using Fail-safe (contact Snowflake)
    - [ ] D. Maybe, depends on table size

22. You need to test a risky UPDATE on a 500GB table. Best approach?
    - [ ] A. Backup to CSV, then restore if needed
    - [ ] B. Create a zero-copy clone and test on that
    - [ ] C. Use Time Travel after the UPDATE
    - [ ] D. Test in small batches

23. Your colleague asks "How long ago can we query historical data?" What do you answer?
    - [ ] A. 24 hours (Standard Edition)
    - [ ] B. Depends on edition and retention settings
    - [ ] C. Unlimited
    - [ ] D. 7 days plus Fail-safe

24. You clone a table, modify 10% of rows. Storage cost increases by:
    - [ ] A. 0% (still shared)
    - [ ] B. ~10% (only changed partitions)
    - [ ] C. 50% (partial duplication)
    - [ ] D. 100% (full duplication)

25. Analyst needs yesterday's data for a report. How do you provide it?
    - [ ] A. Export from backup and send
    - [ ] B. Give them a query with AT(OFFSET => -86400)
    - [ ] C. Create a historical view
    - [ ] D. Run the report yourself

26. You dropped a table by mistake. Can you recover it?
    - [ ] A. No, DROP is permanent
    - [ ] B. Yes, using Time Travel
    - [ ] C. Yes, using UNDROP command
    - [ ] D. Yes, but only within 1 hour

27. Production table needs schema change. Safest approach?
    - [ ] A. Apply change directly
    - [ ] B. Create clone, test change, then apply to production
    - [ ] C. Use Time Travel to revert if needed
    - [ ] D. Create backup first

28. How much does Time Travel cost?
    - [ ] A. Free, included in Snowflake
    - [ ] B. Storage cost for historical data
    - [ ] C. Per-query fee
    - [ ] D. Enterprise Edition only

29. You need a read-only copy of production for reporting. Best solution?
    - [ ] A. Create a materialized view
    - [ ] B. Create a zero-copy clone
    - [ ] C. Set up data sharing
    - [ ] D. Export to separate database

30. Time Travel vs traditional backups - what's the key difference?
    - [ ] A. Time Travel is faster to query historical data
    - [ ] B. Backups are more reliable
    - [ ] C. Time Travel costs less
    - [ ] D. Backups can go back further in time

---

## Answer Key

### Section 1: Time Travel Basics
1.B | 2.B | 3.A | 4.B | 5.B | 6.C | 7.C | 8.B | 9.B | 10.C

### Section 2: Zero-Copy Cloning
11.B | 12.B | 13.C | 14.B | 15.B | 16.B | 17.C | 18.B | 19.B | 20.B

### Section 3: Practical Scenarios
21.C | 22.B | 23.B | 24.B | 25.B | 26.C | 27.B | 28.B | 29.B | 30.A

---

## Scoring

- **27-30:** Expert! You've mastered Time Travel and Cloning
- **23-26:** Strong! Ready for production use
- **18-22:** Good foundation, review specific topics
- **Below 18:** Revisit the exercise and documentation

**Congratulations on completing Exercise 27! 🎉**
