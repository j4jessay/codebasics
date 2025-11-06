# Validation Questions - Exercise 27: Time Travel & Zero-Copy Cloning

## Validation Questions (For Testing Completion)

### 1. Data Loading & Setup

**Q: How many total customer records are loaded by setup.sh?**
A: 10,000

**Q: Approximately how many California customers are in the dataset?**
A: ~963 (varies slightly due to randomization)

---

### 2. Time Travel Concepts

**Q: What SQL clause allows you to query data from before a deletion?**
A: BEFORE(STATEMENT => 'query_id') or AT(TIMESTAMP => '...')

**Q: After deleting 963 CA customers from 10,000 total, how many remain?**
A: ~9,037

**Q: Can you use Time Travel immediately after creating a brand new table?**
A: No - there must be some history/time elapsed

**Q: What is the default Time Travel retention period for Snowflake Standard?**
A: 1 day (24 hours)

---

### 3. Zero-Copy Cloning

**Q: When you clone a table with 10,000 rows, does storage immediately double?**
A: No - zero additional storage initially (copy-on-write)

**Q: What SQL command creates a zero-copy clone?**
A: CREATE TABLE table_test CLONE table_original

**Q: When does a clone start using storage?**
A: When either the original or clone is modified

---

### 4. Recovery Process

**Q: How do you recover deleted CA customers using Time Travel?**
A: INSERT INTO customers SELECT * FROM customers BEFORE(STATEMENT => 'qid') WHERE state = 'CA'

**Q: Why is Time Travel faster than traditional backup/restore?**
A: No data movement required - data isn't actually deleted, just marked

---

### 5. Query IDs

**Q: What Snowflake feature allows referencing a specific query execution?**
A: Query ID (accessed via cursor.sfqid)

---

---

## TODO 1: Execute the Accidental Deletion

**Q1.1:** Did you uncomment the DELETE statement in the code?

**Q1.2:** How many CA customers were deleted from the customers table?

**Q1.3:** What SQL command can you use to verify that CA customers are no longer in the table?

**Q1.4:** What is the total count of records remaining after the deletion?

---

## TODO 2: Use Time Travel to View Historical Data

**Q2.1:** What timestamp did you capture before the deletion occurred?

**Q2.2:** What is the correct syntax to query data using Time Travel with AT(TIMESTAMP => ...)?

**Q2.3:** How many CA customers existed in the table before the deletion when querying using Time Travel?

**Q2.4:** Can you explain the difference between AT and BEFORE clauses in Time Travel?

---

## TODO 3: Recover Deleted Records

**Q3.1:** What SQL pattern did you use to recover the deleted CA customers?

**Q3.2:** How did you ensure you didn't insert duplicate records if the recovery was run multiple times?

**Q3.3:** How many records were successfully recovered?

**Q3.4:** What is the total count of customers in the table after recovery?

**Q3.5:** Can you verify that all recovered CA customers match the original data structure?

---

## TODO 4: Create a Zero-Copy Clone

**Q4.1:** What is the correct SQL syntax to create a zero-copy clone of the customers table?

**Q4.2:** What is the name of the cloned table you created?

**Q4.3:** Does the clone operation create physical copies of the data immediately?

**Q4.4:** What happens to storage when you first create a clone?

---

## TODO 5: Verify the Clone

**Q5.1:** How many records are in the original customers table?

**Q5.2:** How many records are in the customers_test (cloned) table?

**Q5.3:** Do the record counts match between the original and cloned tables?

**Q5.4:** What would happen if you modified a record in the cloned table? Would it affect the original table?

---

## Final Verification Checklist

- [ ] All CA customers (approximately 5,000) were successfully recovered
- [ ] The total customer count is back to 10,000 records
- [ ] The zero-copy clone was created successfully
- [ ] Both original and cloned tables have matching record counts
- [ ] You understand the difference between Time Travel queries (AT/BEFORE)
- [ ] You understand the copy-on-write mechanism for clones
- [ ] The entire recovery process took only seconds

---

## Bonus Understanding Questions

**B1:** What is the default Time Travel retention period for Snowflake Standard Edition?

**B2:** How far back can you query data using Time Travel in Enterprise Edition?

**B3:** In a real production scenario, what other safeguards could prevent accidental deletions?

**B4:** When would you use BEFORE instead of AT in a Time Travel query?

**B5:** What happens to storage costs when you modify data in a cloned table?
