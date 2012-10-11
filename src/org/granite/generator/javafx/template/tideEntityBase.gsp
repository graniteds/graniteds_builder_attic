<%--
  GRANITE DATA SERVICES
  Copyright (C) 2011 GRANITE DATA SERVICES S.A.S.

  This file is part of Granite Data Services.

  Granite Data Services is free software; you can redistribute it and/or modify
  it under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  Granite Data Services is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, see <http://www.gnu.org/licenses/>.

  @author Franck WOLFF
--%><%

    import org.granite.generator.as3.reflect.JavaProperty;
    import org.granite.generator.as3.reflect.JavaFieldProperty;
    import org.granite.generator.as3.reflect.JavaAbstractType;
    
    import java.lang.reflect.Field;
    import java.lang.reflect.Modifier;
    
    import javax.persistence.Version;
    import javax.persistence.EmbeddedId;
    import javax.persistence.Transient;


    // Check if we have at least an id or a uid in jClass hierarchy.    
    JavaAbstractType jc = jClass;
    boolean hasUid = jClass.hasUid();
    while (!hasUid && jc.hasSuperclass()) {
        jc = jc.getSuperclass();
        hasUid = jc.hasUid();
    }
    
    jc = jClass;
    boolean hasId = jClass.hasIdentifiers();
    while (!hasId && jc.hasSuperclass()) {
        jc = jc.getSuperclass();
        hasId = jc.hasIdentifiers();
    }
    
    if (!hasUid && !hasId)
        throw new RuntimeException("Explicit uid field is required for: " + jClass.qualifiedName);

    // Only generates default uid block for the class that owns the id.
    boolean generateDefaultUidMethods = !hasUid && jClass.hasIdentifiers();


    JavaProperty versionField = jClass.getVersion();
    

    Set javaImports = new TreeSet();

    if (generateDefaultUidMethods)
        javaImports.add("java.util.UUID");

	javaImports.add("org.granite.client.javafx.JavaFXObject");
	
    if (jClass.hasIdentifiers()) {
    	javaImports.add("org.granite.messaging.service.annotations.IgnoredMethod")
        javaImports.add("javafx.beans.property.BooleanProperty");
        javaImports.add("javafx.beans.property.SimpleBooleanProperty");
    }

    if (!jClass.hasSuperclass()) {
    	javaImports.add("javafx.event.Event");
    	javaImports.add("javafx.event.EventDispatchChain");
    	javaImports.add("javafx.event.EventHandler");
    	javaImports.add("javafx.event.EventType");
    	javaImports.add("com.sun.javafx.event.EventHandlerManager");

    	javaImports.add("org.granite.client.util.javafx.DataNotifier");
    	javaImports.add("org.granite.client.tide.data.Identifiable");
    	javaImports.add("org.granite.client.tide.data.Lazyable");
    	
    	javaImports.add("org.granite.client.tide.data.Id");
    	javaImports.add("org.granite.client.tide.data.Version");
    }
    
    for (jProperty in jClass.properties) {
    	if (jClass.isLazy(jProperty))
    		javaImports.add("org.granite.client.tide.data.Lazy");
    	
        if (jClass.metaClass.hasProperty(jClass, 'constraints') && jClass.constraints[jProperty] != null) {
        	for (cons in jClass.constraints[jProperty])
        		javaImports.add(cons.packageName + "." + cons.name);
        }
    }

    for (jImport in jClass.imports) {
        if (jImport.hasImportPackage() && jImport.importPackageName != "java.lang" && jImport.importPackageName != jClass.clientType.packageName)
            javaImports.add(jImport.importQualifiedName);
    }

%>/**
 * Generated by Gas3 v${gVersion} (Granite Data Services).
* *
 * WARNING: DO NOT CHANGE THIS FILE. IT MAY BE OVERWRITTEN EACH TIME YOU USE
 * THE GENERATOR. INSTEAD, EDIT THE INHERITED CLASS (${jClass.as3Type.name}.as).
 */

package ${jClass.as3Type.packageName};
<%

///////////////////////////////////////////////////////////////////////////////
// Write Import Statements.

    for (javaImport in javaImports) {%>
import ${javaImport};<%
    }

///////////////////////////////////////////////////////////////////////////////
// Write Class Declaration.%>

@JavaFXObject
public class ${jClass.as3Type.name}Base<%

        boolean implementsWritten = false;
        if (jClass.hasSuperclass()) {
            %> extends ${jClass.superclass.as3Type.name}<%
        } else {
            %> implements Identifiable, Lazyable, DataNotifier<%

            implementsWritten = true;
        }

        for (jInterface in jClass.interfaces) {
            if (!implementsWritten) {
                %> implements ${jInterface.as3Type.name}<%

                implementsWritten = true;
            } else {
                %>, ${jInterface.as3Type.name}<%
            }
        }

    %> {
<%

    ///////////////////////////////////////////////////////////////////////////
    // Write Private Fields.

    if (jClass.hasIdentifiers()) {%>

    private boolean __initialized = true;
    @SuppressWarnings("unused")
	private String __detachedState = null;

    private final BooleanProperty __dirty = new SimpleBooleanProperty(this, "dirty", false);
	
	private EventHandlerManager __handlerManager = new EventHandlerManager(this); 

	@Override
	public EventDispatchChain buildEventDispatchChain(EventDispatchChain tail) {
		return tail.prepend(__handlerManager);
	}
	
	public <T extends Event> void addEventHandler(EventType<T> type, EventHandler<? super T> handler) {
		__handlerManager.addEventHandler(type, handler);
	}
	public <T extends Event> void removeEventHandler(EventType<T> type, EventHandler<? super T> handler) {
		__handlerManager.removeEventHandler(type, handler);
	}
    
    <% if (jClass.hasSuperclass()) {%>@Override<% } %>
    public boolean isInitialized() {
        return __initialized;
    }
    
    @IgnoredMethod
    public BooleanProperty dirtyProperty() {
        return __dirty;
    }
    
    public boolean isDirty() {
        return __dirty.get();
    }
<%
    }
    else if (!jClass.hasSuperclass()) {%>

    public boolean isInitialized() {
        return true;
    }<%
    }

	for (jProperty in jClass.properties) {
	    if (jProperty instanceof org.granite.generator.as3.reflect.JavaMember && jProperty.clientType.propertyTypeName != null) {%>
	${jProperty.access} ${jProperty.clientType.simplePropertyTypeName} ${jProperty.name} = new ${jProperty.clientType.simplePropertyImplTypeName}(this, "${jProperty.name}");<%
	    }
	    else if (jProperty instanceof org.granite.generator.as3.reflect.JavaMember && jProperty.clientType.propertyTypeName == null) {%>
	${jProperty.access} ${jProperty.clientType.name} ${jProperty.name} = new ${jProperty.clientType.simplePropertyImplTypeName}();<%
	    }
	    else if (jProperty.clientType.propertyTypeName != null) {%>
	private ${jProperty.clientType.simplePropertyTypeName} ${jProperty.name} = new ${jProperty.clientType.simplePropertyImplTypeName}(this, "${jProperty.name}");<%
	    }
	}%>
	<%

    ///////////////////////////////////////////////////////////////////////////
    // Write Public Getter/Setter.

    for (jProperty in jClass.properties) {
        if (jProperty != jClass.uid) {
            if (jProperty.readable || jProperty.writable) {
            	if (jProperty.clientType.propertyTypeName != null) {%>
	public ${jProperty.clientType.simplePropertyTypeName} ${jProperty.name}Property() {
		return ${jProperty.name};
	}<%
            	}
                if (jProperty.writable) {
                	if (jProperty.writeOverride) {%>
    @Override<% } %>
    public void set${jProperty.capitalizedName}(${jProperty.clientType.name} value) {<%
        			if (jProperty.clientType.propertyTypeName != null) {%>
        ${jProperty.name}.set(value);<%
        			}
        			else {%>
    	this.${jProperty.name} = value;<%			
        			}%>
    }<%
		        }
                if (jProperty.readable) {
                	if (jProperty == jClass.firstIdentifier) {%>
    @Id<%
                    } else if (jProperty == versionField) {%>
    @Version<%
                    } else if (jClass.isLazy(jProperty)) {%>
    @Lazy<%
                    }
                    if (jClass.metaClass.hasProperty(jClass, 'constraints') && jClass.constraints[jProperty] != null) {
                    	for (cons in jClass.constraints[jProperty]) {%>
    @${cons.name}<%
        					if (!cons.properties.empty) {%>(<%}
        					cons.properties.eachWithIndex{ p, i -> if (i > 0) {%>, <%}; if (p[2] == "java.lang.String") {%>${p[0]}="${p[1]}"<% } else { %>${p[0]}=${p[1]}<% } }
        					if (!cons.properties.empty) {%>)<%}
        				}
                    }
	            	if (jProperty.readOverride) {%>
    @Override<% 
	            	}%>
    public ${jProperty.clientType.name} get${jProperty.capitalizedName}() {<%
					if (jProperty.clientType.propertyTypeName != null) {%>
        return ${jProperty.name}.get();<%
	    			}
					else {%>
		return this.${jProperty.name};<%
					}%>
    }
    <%
                }
            }
        } 
        else {%>
        
    public StringProperty uidProperty() {
    	return ${jClass.uid.name};
    }
    public void setUid(String value) {
        ${jClass.uid.name}.set(value);
    }
    public String getUid() {
        return ${jClass.uid.name}.get();
    }
    <%
        }
    }

    if (generateDefaultUidMethods) {%>

    public void set uid(String value) {
        // noop...
    }
    public String getUid() {<%
        
        // First case: one or multiple (@IdClass) @Id simple fields.
        if (!jClass.firstIdentifier.isAnnotationPresent(EmbeddedId.class)) {
        %>
            if (<%
                for (int i = 0; i < jClass.identifiers.size(); i++) {
                    JavaFieldProperty jId = jClass.identifiers.get(i);
                    %><%= (i > 0) ? " && " : "" %>${jId.name} == null<%
                }%>)
                return UUID.randomUUID().toString().toUpperCase();
            return getClass().getName() + "#[" + <%
                for (int i = 0; i < jClass.identifiers.size(); i++) {
                    JavaFieldProperty jId = jClass.identifiers.get(i);
                    %><%= (i > 0) ? (" + \",\" + ") : "" %>${jId.name}.toString()<%
                }%> + "]";<%
        }
        // Second case: one @EmbeddedId composite field.
        else {
            JavaFieldProperty jId = jClass.firstIdentifier;
        %>
            if (!_${jId.name})
                return UUID.randomUUID().toString().toUpperCase();
            return getClass().getName() + "#[" + <%
                int i = 0;
                for (field in jId.type.declaredFields) {
                    if (!Modifier.isStatic(field.modifiers) &&
                        !Modifier.isTransient(field.modifiers) &&
                        !field.isAnnotationPresent(Transient.class)) {
                        %><%= (i++ > 0) ? (" + \",\" + ") : "" %>${jId.name}.${field.name}.toString()<%
                    }
                }%> + "]";<%
        }
        %>
        }<%
    }

    ///////////////////////////////////////////////////////////////////////////
    // Write Public Getters/Setters for Implemented Interfaces.

    if (jClass.hasInterfaces()) {
        for (jProperty in jClass.interfacesProperties) {
            if (jProperty.readable || jProperty.writable) {%>
<%
                if (jProperty.writable) {%>
    public function set${jProperty.capitalizedName}(${jProperty.clientType.name} value) {
    }<%
                }
                if (jProperty.readable) {%>
    public ${jProperty.clientType.name} get${jProperty.capitalizedName}() {
        return ${jProperty.clientType.nullValue};
    }<%
                }
            }
        }
    }%>
}