/**
 * Copyright (C) 2016 Joshua Auerbach 
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.qcert.sql;

import java.util.ArrayList;

import com.facebook.presto.sql.parser.ParsingException;

import java.util.List;

import com.facebook.presto.sql.parser.SqlParser;
import com.facebook.presto.sql.parser.StatementSplitter;
import com.facebook.presto.sql.tree.Node;
import com.facebook.presto.sql.tree.Statement;

/**
 * Utilities that work with presto-parser to produce other useful forms 
 */
public class PrestoEncoder {
	/**
	 * Encode a list of presto tree nodes as an S-expression for importing into Coq code
	 * @param toEncode the list of presto tree nodes to encode 
	 * @return the S-expression string
	 */
	public static String encode(List<? extends Node> toEncode) {
		StringBuilder buffer = new StringBuilder();
		buffer.append("(statements ");
		for(Node node : toEncode) {
			encode(buffer, node);
		}
		buffer.append(")");
		return buffer.toString();
	}
	
	/**
	 * Encode an individual presto tree node as an S-expression using an existing buffer
	 * @param buffer the existing buffer
	 * @param toEncode the presto tree node
	 * @return the buffer, for convenience
	 */
	public static StringBuilder encode(StringBuilder buffer, Node toEncode) {
		return new EncodingVisitor().process(toEncode, buffer);
	}

	/**
	 * Parse a SQL source in string form into one or more presto nodes and then encode the result as
	 *   an S-expression string
	 * @param sourceString the SQL source string to parse and then encode
	 * @param interleaved if true, each statement is parsed then encoded with the outer loop iterating through statements;
	 *   otherwise, all parsing is done, and then all encoding 
	 * @return the S-expression string
	 */
	public static String parseAndEncode(String sourceString, boolean interleaved) {
		if (interleaved)
			return interleavedParseAndEncode(sourceString);
		return encode(parse(sourceString));
	}

	/**
	 * Alternative parse/encode loop useful when there are lots of statements.  Isolates what parses but does not encode from
	 *   what doesn't parse at all
	 * @param sourceString the source string
	 * @return the parsed String, which might be vacuous, while rejecting all statements that don't parse (encoding errors still
	 *   cause termination)
	 */
	private static String interleavedParseAndEncode(String sourceString) {
		StatementSplitter splitter = new StatementSplitter(sourceString);
		SqlParser parser = new SqlParser();
		StringBuilder buffer = new StringBuilder().append("(statements ");
		int successes = 0;
		
		for(StatementSplitter.Statement statement : splitter.getCompleteStatements()) {
			String body = statement.statement();
			Statement result;
			try {
				result = parser.createStatement(body);
			} catch (Exception e) {
				String msg = e.getMessage();
				if (msg == null)
					e.printStackTrace();
				System.out.println(msg == null ? e.toString() : msg);
				continue;
			}
			try {
				encode(buffer, result);
				successes++;
			} catch (Exception e) {
				System.out.println("Successes: " + successes);
				throw e;
			}
		}
		System.out.println("Successes: " + successes);
		return buffer.append(")").toString();
	}

	/**
	 * Parse a SQL source string.  First separates it into statements, then parses the Statements.
	 * @param sourceString the SQL source string
	 * @return the parsed statement(s) as an List<Statement>
	 */
	private static List<Statement> parse(String query) {
		StatementSplitter splitter = new StatementSplitter(query);
		SqlParser parser = new SqlParser();
		ArrayList<Statement> results = new ArrayList<Statement>(1);

		for(com.facebook.presto.sql.parser.StatementSplitter.Statement statement : splitter.getCompleteStatements()) {
			String body = statement.statement();
			Statement result = parser.createStatement(body);
			results.add(result);
		}

		if(results.isEmpty()) {
			throw new ParsingException("input query does not contain any statements");
		}

		return results;
	}
}
