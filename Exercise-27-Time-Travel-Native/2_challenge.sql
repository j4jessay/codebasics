-- ============================================================
-- EXERCISE 27: TIME TRAVEL & ZERO-COPY CLONING
-- FILE: 2_challenge.sql
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- ============================================================
-- TODO 1: UNDERSTAND INITIAL STATE
-- ============================================================
/*
CHALLENGE: Before simulating a disaster, understand your data.

REQUIREMENTS:
1. Count total customers
2. Count California customers (state = 'CA')
3. Calculate what percentage are from CA
4. **CRITICAL:** Record these numbers - you'll verify recovery later!

LEARNING OBJECTIVE:
Always know your baseline before testing disaster recovery.
*/

-- YOUR CODE HERE (Count total customers):



-- YOUR CODE HERE (Count CA customers):



-- YOUR CODE HERE (Calculate CA percentage):



/*
RECORD YOUR BASELINE:
- Total customers: _________________
- CA customers: _________________
- CA percentage: _________________ %
- Current timestamp: _________________ (use SELECT CURRENT_TIMESTAMP())

⚠️ CRITICAL: You MUST capture current timestamp for Time Travel!
Write it down or keep it in a comment.
*/


-- ============================================================
-- TODO 2: DISASTER STRIKES! Execute Deletion
-- ============================================================
/*
CHALLENGE: A junior analyst made a terrible mistake!

SCENARIO:
They meant to run:
  SELECT * FROM customers WHERE state = 'CA';

But accidentally ran:
  DELETE FROM customers WHERE state = 'CA';

REQUIREMENTS:
1. BEFORE deletion, capture CURRENT_TIMESTAMP() (already done above, right?)
2. Execute the DELETE command
3. Verify the deletion with a COUNT query
4. Calculate how many customers were lost

IMPORTANT: This is INTENTIONAL! We'll recover the data with Time Travel.

⚠️ If you didn't capture timestamp above, DO IT NOW before deletion!
*/

-- YOUR CODE HERE (Delete CA customers - yes, really do it!):



-- YOUR CODE HERE (Verify deletion):



-- YOUR CODE HERE (Count remaining customers):



/*
RECORD DISASTER IMPACT:
- Total customers after deletion: _________________
- CA customers remaining: _________________ (should be 0)
- Customers lost: _________________

How would this feel in a real production scenario?
_____________________________________________________________
_____________________________________________________________
*/


-- ============================================================
-- TODO 3: TIME TRAVEL - Query Historical Data
-- ============================================================
/*
CHALLENGE: Use Time Travel to see data BEFORE the deletion.

LEARNING OBJECTIVE:
Understand AT and BEFORE clauses for querying historical data.

RESEARCH FIRST (use Snowflake docs if needed):

Question 1: What are the two main Time Travel clauses?
Answer:
- Clause 1: _________________
- Clause 2: _________________

Question 2: What's the difference between them?
Answer: _____________________________________________________________

Question 3: What's the syntax for AT with timestamp?
Answer: _____________________________________________________________

NOW CODE IT:
Write a query to count CA customers as they existed BEFORE deletion.
Use the timestamp you captured in TODO 1.

SYNTAX HINT:
SELECT COUNT(*) FROM table_name
AT(TIMESTAMP => 'your_timestamp'::TIMESTAMP)
WHERE state = 'CA';
*/

-- YOUR CODE HERE:



/*
RESULT VERIFICATION:
- CA customers in history: _________________
- Does this match your baseline from TODO 1? _________________
- What does this prove about Time Travel? _____________________
_____________________________________________________________
*/


-- ============================================================
-- TODO 4: RECOVER DELETED DATA
-- ============================================================
/*
CHALLENGE: Bring back the deleted customers!

APPROACH:
Use INSERT INTO ... SELECT with Time Travel to recover deleted data.

REQUIREMENTS:
1. INSERT INTO customers table
2. SELECT from customers using Time Travel (your timestamp)
3. Filter for state = 'CA' only
4. Verify recovery with a COUNT query

CRITICAL THINKING:
Should you worry about duplicate records?
Answer: _____________________________________________________________
_____________________________________________________________

Why or why not?
_____________________________________________________________
*/

-- YOUR CODE HERE (Recovery query):



-- YOUR CODE HERE (Verify recovery - count CA customers):



-- YOUR CODE HERE (Verify total count):



/*
RECOVERY VERIFICATION:
- CA customers after recovery: _________________
- Total customers after recovery: _________________
- Does this match your original baseline? _________________
- Time taken to recover: _________________ seconds

What would this have taken in a traditional database?
_____________________________________________________________
_____________________________________________________________

Why is Snowflake Time Travel so powerful?
_____________________________________________________________
_____________________________________________________________
*/


-- ============================================================
-- TODO 5: ZERO-COPY CLONE - Create Test Environment
-- ============================================================
/*
CHALLENGE: Create an instant copy of the customers table.

LEARNING OBJECTIVE:
Understand zero-copy cloning and copy-on-write mechanics.

PART A: Create the Clone

SYNTAX HINT:
CREATE OR REPLACE TABLE table_test CLONE table_original;
*/

-- YOUR CODE HERE (Create clone):



/*
PART B: Verify the Clone

Check that the clone has the same data as the original.
*/

-- YOUR CODE HERE (Count in original):



-- YOUR CODE HERE (Count in clone):



/*
PART C: Understand Copy-on-Write

Answer these questions BEFORE testing:

1. Did creating the clone take a long time?
Answer: _________________

2. Did it immediately double your storage costs?
Answer: _________________

3. What will happen when you UPDATE a record in the clone?
Answer: _____________________________________________________________

4. Will the original table be affected?
Answer: _________________

NOW TEST IT:
*/

-- Update one customer in the CLONE
UPDATE customers_test
SET first_name = 'TimeTravel'
WHERE customer_id = 'CUST00001';

-- Check the clone
SELECT * FROM customers_test WHERE customer_id = 'CUST00001';

-- Check the ORIGINAL table
SELECT * FROM customers WHERE customer_id = 'CUST00001';

/*
CLONE BEHAVIOR ANALYSIS:
- Did the original table change? _________________
- Why or why not? _____________________________________________________________
- When does storage cost increase? _____________________________________________
- What is copy-on-write? ______________________________________________________
_____________________________________________________________
*/


-- ============================================================
-- CHALLENGE COMPLETE!
-- ============================================================

SELECT
  '🎉 Challenge Complete!' AS status,
  'You successfully recovered from disaster!' AS achievement,
  'Review 3_solution.sql to compare approaches' AS next_step;

/*
REFLECTION QUESTIONS:

1. How did Time Travel change your view of "deleted" data?
_____________________________________________________________
_____________________________________________________________

2. In what scenarios would zero-copy cloning be useful?
_____________________________________________________________
_____________________________________________________________

3. What are the limitations of Time Travel? (Think about retention periods)
_____________________________________________________________
_____________________________________________________________

4. How would you explain Time Travel to a non-technical manager?
_____________________________________________________________
_____________________________________________________________

NEXT STEPS:
☐ Compare your solution with 3_solution.sql
☐ Complete validation_quiz.md
☐ Try 4_advanced_exploration.sql
☐ Share your "wow" moment with your team!

Congratulations on mastering Time Travel! ⏰
*/
