# Validation Questions - Exercise 26: Clustering Keys & Query Performance

## Validation Questions (For Testing Completion)

### 1. Data Loading & Setup

**Q: How many total sales records are loaded by setup.sh?**
A: 50,000

**Q: What regions are included in the sales dataset?**
A: US_EAST, US_WEST, EU, ASIA

**Q: What date range does the sales data cover?**
A: January 2024 - December 2024

---

### 2. Clustering Concepts

**Q: What is Snowflake's automatic data organization feature called?**
A: Micro-partitioning

**Q: What SQL clause is used to define clustering keys when creating a table?**
A: CLUSTER BY

**Q: What are the clustering keys used in this exercise?**
A: order_date and region

**Q: What is partition pruning?**
A: Snowflake's ability to skip micro-partitions that don't contain relevant data based on clustering keys

---

### 3. Clustering Depth

**Q: What function measures the clustering quality of a table?**
A: SYSTEM$CLUSTERING_DEPTH

**Q: What is considered excellent clustering depth?**
A: Depth < 2

**Q: What does a higher clustering depth indicate?**
A: Data is less organized, requiring more partitions to scan

---

### 4. Query Performance

**Q: For the query filtering US_EAST region in October 2024, which table scans fewer partitions?**
A: The clustered table (sales_clustered)

**Q: What is the expected performance improvement with clustering?**
A: 3-5x faster queries

**Q: Where can you visualize partition scans in Snowflake?**
A: Query Profile in Snowflake UI

---

### 5. Table Creation

**Q: What SQL pattern creates a clustered table with data from another table?**
A: CREATE TABLE table_name CLUSTER BY (columns) AS SELECT * FROM source_table

**Q: Can you add clustering keys to an existing table?**
A: Yes, using ALTER TABLE with CLUSTER BY

---

---

## TODO 1: Query the Non-Clustered Table

**Q1.1:** What is the correct SQL syntax to query sales for US_EAST region in October 2024?

**Q1.2:** How many rows match the filter criteria (region='US_EAST' and October 2024)?

**Q1.3:** What was the execution time for querying the non-clustered table?

**Q1.4:** Did you measure the time using Python's time.time() function?

---

## TODO 2: Create a Clustered Table

**Q2.1:** What is the complete SQL statement to create a clustered table?

**Q2.2:** Why are order_date and region chosen as clustering keys?

**Q2.3:** What does the CREATE OR REPLACE clause do?

**Q2.4:** How many records were copied from sales_non_clustered to sales_clustered?

**Q2.5:** Does creating a clustered table physically sort all the data immediately?

---

## TODO 3: Check Clustering Depth

**Q3.1:** What is the exact SQL syntax to check clustering depth?

**Q3.2:** What clustering depth did you observe for the sales_clustered table?

**Q3.3:** Is the clustering depth below 2 (excellent)?

**Q3.4:** What would a clustering depth of 10+ indicate about your table?

---

## TODO 4: Query the Clustered Table

**Q4.1:** Did you use the same query as TODO 1 but on the sales_clustered table?

**Q4.2:** What was the execution time for querying the clustered table?

**Q4.3:** How many rows were returned from the clustered table?

**Q4.4:** Should the row count match between clustered and non-clustered queries?

---

## TODO 5: Compare and Display Results

**Q5.1:** What is the time difference between non-clustered and clustered queries?

**Q5.2:** What is the performance improvement ratio (e.g., 3.5x faster)?

**Q5.3:** Did the clustered table perform better than the non-clustered table?

**Q5.4:** What message explains why clustering improves performance?

---

## Final Verification Checklist

- [ ] 50,000 sales records were loaded into sales_non_clustered table
- [ ] The non-clustered query executed successfully
- [ ] The clustered table was created with CLUSTER BY (order_date, region)
- [ ] Clustering depth was checked and is < 2
- [ ] The clustered query executed successfully
- [ ] Performance comparison shows improvement
- [ ] Both queries returned the same number of rows
- [ ] You understand how partition pruning works

---

## Bonus Understanding Questions

**B1:** What happens to clustering over time as new data is inserted?

**B2:** What is automatic reclustering in Snowflake?

**B3:** How many clustering keys can you define on a table (maximum)?

**B4:** Would clustering help if you never filter by the clustering key columns?

**B5:** What are the trade-offs of clustering (benefits vs. costs)?

**B6:** How does clustering affect DML operations (INSERT, UPDATE, DELETE)?

**B7:** In what scenarios should you NOT use clustering?

**B8:** How can you view the Query Profile to see partition pruning in action?

---

## Advanced Validation Questions

**A1:** If you had a query that filtered only by product_id (not in clustering keys), would the clustered table still be faster?

**A2:** What would happen if you reversed the clustering key order to (region, order_date)?

**A3:** How would you monitor clustering health in a production environment?

**A4:** What is the difference between clustering and traditional indexes?

**A5:** Can you cluster a table by columns that are frequently updated?

---

## Real-World Scenarios

**S1:** Your analysts run queries primarily filtering by customer_region and sale_date. What clustering keys would you recommend?

**S2:** A table has 100 million rows and analysts complain about slow queries. Walk through your troubleshooting steps.

**S3:** After clustering, queries are still slow. What other optimization techniques could you try?

**S4:** How would you explain the ROI of clustering to a non-technical stakeholder?

**S5:** When migrating from a traditional database to Snowflake, how do you decide which tables need clustering?
