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
package org.qcert.camp.pattern;

import org.qcert.camp.data.CampData;
import org.qcert.camp.data.NatData;
import org.qcert.camp.data.StringData;

/**
 * Represents a CAMP Constant pattern
 */
public final class ConstPattern extends CampPattern {
	private final CampData data;

	/**
	 * Make a new PatternConst
	 * @param data the CampData for the represented constant
	 */
	public ConstPattern(CampData data) {
		this.data = data;
	}

	/** Convenience constructor for String constants */
	public ConstPattern(String value) {
		this(new StringData(value));
	}
	
	/** Convenience constructor for integral constants */
	public ConstPattern(long value) {
		this(new NatData(value));
	}
	
	/**
	 * @return the data
	 */
	public CampData getData() {
		return data;
	}
	
	/* (non-Javadoc)
	 * @see org.qcert.camp.pattern.CampPattern#getKind()
	 */
	@Override
	public Kind getKind() {
		return Kind.pconst;
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.CampAST#getOperands()
	 */
	@Override
	protected Object[] getOperands() {
		return new Object[] {data};
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.CampAST#getTag()
	 */
	@Override
	protected String getTag() {
		return "Pconst";
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		return data.toString();
	}
}
