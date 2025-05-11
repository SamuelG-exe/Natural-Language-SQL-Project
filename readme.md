
# Natural Language SQL Project

This project explores how well a natural language interface (powered by ChatGPT) can convert English questions into SQL queries and return useful, human-readable answers from a structured database. The dataset models users, goals, groups, and progress tracking—similar to what might be used in a productivity or accountability app.

## Queries I thought it did well on

**Question**: Which users are in more than one group?

**GPT SQL Response**:
```sql
SELECT u.id, u.first_name, u.last_name
FROM users u
JOIN user_groups ug ON u.id = ug.user_id
GROUP BY u.id
HAVING COUNT(DISTINCT ug.group_id) > 1;
```

**Friendly Response**: Users in multiple groups are User2 Last2, User3 Last3, and User5 Last5.

---

**Question**: Which groups have both members and admins?

**GPT SQL Response**:
```sql
SELECT DISTINCT g.id, g.name
FROM groups g
JOIN user_groups ug_member ON g.id = ug_member.group_id AND ug_member.role = 'member'
JOIN user_groups ug_admin ON g.id = ug_admin.group_id AND ug_admin.role = 'admin';
```

**Friendly Response**: Group2 has both members and admins.

---

**Question**: Are there any users who are not in any group?

**GPT SQL Response**:
```sql
SELECT u.id, u.first_name, u.last_name
FROM users u
LEFT JOIN user_groups ug ON u.id = ug.user_id
WHERE ug.user_id IS NULL;
```

**Friendly Response**: Users not in any group: User1, User4.

---

## Questions that it tripped up on

**Question**: Which goals have daily reporting intervals?

**GPT SQL Response**:
```sql
ite
SELECT * FROM goals WHERE reporting_interval = 'daily';
```

**Error**: Near "ite": syntax error

For somereason the AI returned an sql statement that included the faulty additional text "ite"

---

**Question**: Which user has the highest streak length overall?

**GPT SQL Response**:
```sql
SELECT u.first_name, u.last_name, s.user_id, MAX(s.highest_len) AS highest_streak
FROM streaks s
JOIN users u ON s.user_id = u.id
GROUP BY s.user_id
ORDER BY highest_streak DESC
LIMIT 1;
```

**Friendly Response**: User1 has the highest streak length of 19.

However, another query returned `User5` as the correct result. Additionally when we look at the data:
```
(4, 5, 5, 9, '2025-05-05', 19, '2025-05-10 23:45:49', '2025-05-10 23:45:49'),
(5, 6, 1, 7, '2025-05-05', 19, '2025-05-10 23:45:49', '2025-05-10 23:45:49');
```
We can see they share a highest streak and the AI hallucinated a response stating that one was higher then the other when in reality they were tied.

---

## Prompting Strategies

### Zero-Shot Strategy
The zero-shot strategy was employed where the model was asked to generate SQL queries for a given question without any prior examples or domain-specific context beyond the database schema. The prompt simply included the database structure and asked the model to provide a SQL query to answer the user query. 

#### Observations:
- The model was able to generate correct SQL queries for most questions, such as "Which users are in more than one group?" where it provided the correct query and response.
- For questions involving more complex joins or specific conditions, the model performed well in generating syntactically correct SQL queries, but some edge cases, such as errors due to syntax mistakes ("goals with daily reporting intervals"), required additional attention.
- The results were mostly accurate, but responses were more verbose and less human-friendly.

### Single-Domain Double-Shot Strategy
In the single-domain double-shot strategy, the model was provided not only the database schema but also a specific example query with the result, and then asked to generate a query for a similar question. This prompt technique aimed to show the model how to handle a certain type of query, increasing its ability to handle similar questions.

#### Observations:
- This strategy resulted in more refined SQL queries. For example, it generated SQL queries like `SELECT user_id FROM user_groups GROUP BY user_id HAVING COUNT(DISTINCT group_id) > 1;` to answer questions about users in multiple groups.
- The model's responses appeared to be more reliable and specific, and the SQL queries generated for these questions were often well-formed with fewer syntax errors.
- The friendly responses (after querying the database) were more concise and human-readable compared to the zero-shot strategy.


# Prompting Strategies Comparison

## Prompting Strategy Comparison: Zero-Shot vs. Double-Shot

### Zero-Shot Strategy  
Prompts had no examples—just schema and a request for a query.

- **Query Style:** More verbose; included extra columns like user names.  
- **Example:**  
  ```sql
  SELECT u.id, u.first_name, u.last_name 
  FROM users u 
  JOIN user_groups ug ON u.id = ug.user_id 
  GROUP BY u.id 
  HAVING COUNT(DISTINCT ug.group_id) > 1;
  ```
- **Errors:** One syntax error (`"ite SELECT"`) caused query failure.  
- **Inconsistencies:** Style varied across questions.

### Double-Shot Strategy  
Prompts included one example query before requesting a new one.

- **Query Style:** Simpler, more focused; typically selected only the needed columns (e.g., `user_id`).  
- **Errors:** No syntax errors observed, but one logic error was present.  
- **Issue:** The model hallucinated a unique top streak holder when the data showed a tie—both User1 and User5 had a streak of 19, but only one was returned.

---

## Key Differences

| Category             | Zero-Shot                     | Double-Shot                                 |
|----------------------|-------------------------------|---------------------------------------------|
| Query Complexity     | Verbose                       | Concise, minimal columns                    |
| Syntax Errors        | One error detected            | None                                        |
| Logic Errors         | None identified               | One hallucinated a unique top streak holder |
| Column Selection     | Often includes extra details  | Focused on requested fields                 |
| Style Consistency    | Inconsistent                  | Consistent across prompts                   |
| Result Accuracy      | Incorrect due to hallucination| Incorrect due to hallucination              |

---

## Conclusion  
Double-shot prompting yielded more consistent, syntactically correct, and focused queries. However, it still hallucinated a unique result when the data showed a tie. Though this error was not unique to Double-shot, I think chat just struggles with matching rows. Zero-shot produced more verbose queries and suffered from syntax inconsistency, but the core mistake around streak ties was shared.


