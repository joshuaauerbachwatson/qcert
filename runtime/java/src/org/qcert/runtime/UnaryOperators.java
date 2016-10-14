/*
 * Copyright 2015-2016 IBM Corporation
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

package org.qcert.runtime;

import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.Map.Entry;
import java.util.Set;
import java.util.TreeSet;

import com.google.gson.*;

public class UnaryOperators {
	
	private static Set<String> collToBrands(JsonArray coll) {
		final Set<String> dst = new HashSet<String>(coll.size());
		for(final JsonElement elem : coll) {
			dst.add(elem.getAsString());
		}
		return dst;
	}

	private static TreeSet<JsonElement> collToTreeSet(JsonArray coll) {
		final TreeSet<JsonElement> dst = new TreeSet<JsonElement>(DataComparator.getComparator());
		for(final JsonElement elem : coll) {
			dst.add(elem);
		}
		return dst;
	}


	public static JsonElement abs(JsonElement e) {
		return new JsonPrimitive(Math.abs(e.getAsLong()));
	}

	public static JsonElement log2(JsonElement e) {
		return new JsonPrimitive(Math.log(e.getAsLong()) / Math.log(2));
	}
	public static JsonElement sqrt(JsonElement e) {
		return new JsonPrimitive((Math.sqrt(e.getAsLong())));
	}
	public static JsonElement neg(JsonElement e) {
		return new JsonPrimitive(! e.getAsBoolean());
	}
	
	public static JsonElement coll(JsonElement e) {
		JsonArray dst = new JsonArray();
		dst.add(e);
		return dst;
	}
	public static JsonElement count(JsonElement e) {
		return new JsonPrimitive(e.getAsJsonArray().size());
	}
	
	public static JsonElement flatten(JsonElement e) {
		final JsonArray dst = new JsonArray();
		final JsonArray src = e.getAsJsonArray();
		for(final JsonElement elem : src) {
			dst.addAll(elem.getAsJsonArray());
		}
		return dst;
	}
	
	public static JsonElement rec(String f, JsonElement e) {
		JsonObject dst = new JsonObject();
		dst.add(f, e);
		return dst;
	}
	public static JsonElement dot(String f, JsonElement e) {
		return e.getAsJsonObject().get(f);
	}
	
	public static JsonElement remove(String f, JsonElement e) {
		final JsonObject er = e.getAsJsonObject();
		final JsonObject dst = new JsonObject();
		for(Entry<String, JsonElement> entry : er.entrySet()) {
			String key = entry.getKey();
			if(! f.equals(key)) {
				dst.add(key, entry.getValue());
			}
		}
		return dst;
	}
	
	public static JsonElement project(Collection<String> fs, JsonElement e) {
		final JsonObject er = e.getAsJsonObject();
		final JsonObject dst = new JsonObject();
		for(Entry<String, JsonElement> entry : er.entrySet()) {
			String key = entry.getKey();
			if(fs.contains(key)) {
				dst.add(key, entry.getValue());
			}
		}
		return dst;
	}
	
	public static JsonElement distinct(JsonElement e) {
		final JsonArray ec = e.getAsJsonArray();
		final TreeSet<JsonElement> treeSet = collToTreeSet(ec);
		JsonArray dst = new JsonArray();
		for(JsonElement elem : treeSet) {
			dst.add(elem);
		}

		return dst;
	}
	
	
	private static long sum_helper(JsonArray ec) {
		long acc = 0;
		for (JsonElement elem : ec) {
			acc += elem.getAsLong();
		}
		return acc;
	}

	public static JsonElement sum(JsonElement e) {
		return new JsonPrimitive(sum_helper(e.getAsJsonArray()));
	}
	
	private static void tostring(StringBuilder sb, JsonPrimitive jp) {
	    if (jp.isString()) {
		sb.append(jp.getAsString());
	    } else {
		sb.append(jp.toString());
	    }
	}
	
//	public static void tostring(StringBuilder sb, Number n) {
//		sb.append(n);
//	}
	
	public static void tostring(StringBuilder sb, JsonArray ec) {
		String elemstrings[] = new String[ec.size()];
		for(int i = 0; i < ec.size(); i ++) {
			final JsonElement elem = ec.get(i);
			StringBuilder sbelem = new StringBuilder();
			tostring(sbelem, elem);
			elemstrings[i] = sbelem.toString();
		}
		Arrays.sort(elemstrings);
		
		sb.append("[");
		boolean isFirst = true;
		for(String elem : elemstrings) {
			if(isFirst) {
				isFirst = false;
			} else {
				sb.append(", ");
			}

			sb.append(elem);
		}
		sb.append("]");
	}

	private static <V> void tostring(StringBuilder sb, JsonObject o){
		sb.append("{");
		
		boolean isFirst = true;
		for(Entry<String, JsonElement>entry : o.entrySet()) {
			if(isFirst) {
				isFirst = false;
			} else {
				sb.append(",");
			}
			sb.append(entry.getKey());
			sb.append(":");
			tostring(sb,entry.getValue());
		}
		sb.append("}");
	}

	private static void tostring(StringBuilder sb, JsonElement e) {
		if(e == null || e.isJsonNull()) {
			sb.append("null");
		} else if (e.isJsonPrimitive()) {
			tostring(sb, e.getAsJsonPrimitive());
		} else if(e.isJsonArray()) {
			tostring(sb, e.getAsJsonArray());
		} else if(e.isJsonObject()) {
			tostring(sb, e.getAsJsonObject());
		} else {
			sb.append(e.toString());
		}
	}
	
	public static JsonPrimitive tostring(JsonElement e) {
		StringBuilder sb = new StringBuilder();
		tostring(sb, e);
		return new JsonPrimitive(sb.toString());
	}
	
	public static JsonElement substring(int start, int end, JsonElement e) {
		String str = e.getAsJsonPrimitive().getAsString();
		return new JsonPrimitive(str.substring(start, end));
	}

	public static JsonElement substring(int start, JsonElement e) {
		String str = e.getAsJsonPrimitive().getAsString();
		return new JsonPrimitive(str.substring(start));
	}

	public static JsonElement left(JsonElement e) {
		return rec("left", e);
	}
	public static JsonElement right(JsonElement e) {
		return rec("right", e);
	}
	
	public static JsonElement brand(Collection<String> brands, JsonElement e) {
		final JsonObject dst = new JsonObject();
		dst.add("data", e);
		
		JsonArray brands_dst = new JsonArray();
		for(final String br : brands) {
			brands_dst.add(br);
		}
		dst.add("type", brands_dst);
		return dst;
	}
	public static JsonElement unbrand(JsonElement e) {
		return e.getAsJsonObject().get("data");
	}
	
	public static JsonElement cast(Hierarchy hierarchy, Collection<String> brands, JsonElement e) {
		final JsonObject er = e.getAsJsonObject();
		final JsonArray typs = er.get("type").getAsJsonArray();
		Set<String> actualBrands = collToBrands(typs);
		if(hierarchy.isAssignableFrom(brands, actualBrands)) {
			return left(e);
		} else {
			return right(e);
		}
	}
	
	private static final JsonElement dnone = mk_right_none();
	
	private static JsonElement mk_right_none() {
		return right(JsonNull.INSTANCE);
	}

	public static JsonElement singleton(JsonElement e) {
		JsonArray ec = e.getAsJsonArray();
		if(ec.size() == 1) {
			return left(ec.get(0));
		} else {
			return dnone;
		}
	}
	
	public static JsonElement list_mean(JsonElement e) {
		final JsonArray ec = e.getAsJsonArray();
		if(ec.size() == 0) {
			return new JsonPrimitive(0L);
		} else {
			return new JsonPrimitive(sum_helper(ec) / ec.size());
		}
	}
	public static JsonElement list_min(JsonElement e) {
		final JsonArray ec = e.getAsJsonArray();
		long min = Long.MAX_VALUE;
		for(final JsonElement elem : ec) {
			final long eleml = elem.getAsLong();
			if(eleml < min) {
				min = eleml;
			}
		}
		return new JsonPrimitive(min);
	}
	public static JsonElement list_max(JsonElement e) {
		final JsonArray ec = e.getAsJsonArray();
		long max = Long.MIN_VALUE;
		for(final JsonElement elem : ec) {
			final long eleml = elem.getAsLong();
			if(eleml > max) {
				max = eleml;
			}
		}
		return new JsonPrimitive(max);
	}

	// floating point
	public static JsonElement float_neg(JsonElement e) {
		return new JsonPrimitive(- e.getAsDouble());
	}
	public static JsonElement float_sqrt(JsonElement e) {
		return new JsonPrimitive(Math.sqrt(e.getAsDouble()));
	}
	public static JsonElement float_exp(JsonElement e) {
		return new JsonPrimitive(Math.exp(e.getAsDouble()));
	}
	public static JsonElement float_log(JsonElement e) {
		return new JsonPrimitive(Math.log(e.getAsDouble()));
	}
	public static JsonElement float_log10(JsonElement e) {
		return new JsonPrimitive(Math.log10(e.getAsDouble()));
	}
	public static JsonElement float_of_int(JsonElement e) {
		return new JsonPrimitive(e.getAsLong());
	}
	public static JsonElement float_ceil(JsonElement e) {
		return new JsonPrimitive(Math.ceil(e.getAsDouble()));
	}
	public static JsonElement float_floor(JsonElement e) {
		return new JsonPrimitive(Math.floor(e.getAsDouble()));
	}
	public static JsonElement float_truncate(JsonElement e) {
		return new JsonPrimitive(e.getAsNumber().longValue());
	}
	public static JsonElement float_abs(JsonElement e) {
		return new JsonPrimitive(Math.abs(e.getAsDouble()));
	}
	
	public static double float_sum_helper(JsonArray ec) {
		double acc = 0.0d;
		for (JsonElement elem : ec) {
			acc += elem.getAsDouble();
		}
		return acc;
	}
	
	public static JsonElement float_sum(JsonElement e) {
		return new JsonPrimitive(float_sum_helper(e.getAsJsonArray()));
	}
	
	public static JsonElement float_list_mean(JsonElement e) {
		final JsonArray ec = e.getAsJsonArray();
		if(ec.size() == 0) {
			return new JsonPrimitive(0d);
		} else {
			return new JsonPrimitive(float_sum_helper(ec) / (double)ec.size());
		}

	}
	public static JsonElement float_list_min(JsonElement e) {
		final JsonArray ec = e.getAsJsonArray();
		double min = Double.MAX_VALUE;
		for(final JsonElement elem : ec) {
			final double eleml = elem.getAsDouble();
			if(eleml < min) {
				min = eleml;
			}
		}
		return new JsonPrimitive(min);
	}
	
	public static JsonElement float_list_max(JsonElement e) {
		final JsonArray ec = e.getAsJsonArray();
		double max = Double.MIN_VALUE;
		for(final JsonElement elem : ec) {
			final double eleml = elem.getAsDouble();
			if(eleml > max) {
				max = eleml;
			}
		}
		return new JsonPrimitive(max);
	}

	public static JsonElement time_to_scale(JsonElement e) {
		// TODO: do we actually need this operator
		// also, do timescales need to be actual data
		// or are they just things that operators can be given
		// (so time_point_as and time_point_shift becomes parameterized unary operators)
		// final TimePoint tp = BinaryOperators.asTimePoint(e);
		return null;
	}
	public static JsonElement time_from_string(JsonElement e) {
		// since we are storing times as strings anyway
		return e;
	}
	
	public static JsonElement sql_date_from_string(JsonElement e) {
		return e;
	}

	public static JsonElement sql_date_interval_from_string(JsonElement e) {
		return e;
	}

	public final static int DAY = 1;
	public final static int MONTH = 2;
	public final static int YEAR = 3;
	
	public static JsonElement sql_get_date_component(int part, JsonElement e) {
		return e;
	}

}
