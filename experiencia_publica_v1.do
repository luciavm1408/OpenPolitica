/***************************************************************************************************
	Projecto: 		Open Política - Datos del CV

	Equipo:			Contenido

	Autores:		Lucía Valdivieso
	
	Descripción: 	- Junta las bases de datos
					- Crea clasificador de tipo de experiencia laboral
					- Genera estadísticas de subgrupos x caracterísicas

	Input:			- BD en CSV compartidos por Jorge

	Output:			- BD a nivel de candidato
					- Reporte con estadísticas
					
	Next step:		- Afinar variables y filtros
					  
	Stata version: 	16.0
***************************************************************************************************/
// Perdón por el spanglish

clear 		all
set 		more off


* Set directory in the location of the temporal folder
cd			"C:\Users\universidad\OneDrive - Universidad del Pacífico\01.Lucía\OpenPolitica\3.Temp"

* Define access routes macros
global 		input "../1.Input/" 		// Location of the original databases
global 		codes "../2.Codes/"		// Location of the codes
global 		output "../4.Output/"		// Location of final databases, tables and graphs

* Programs
//ssc 		install fre
//ssc 		install orth_out
e 
****************************************************************************************************
* 1. Opening, cleaning the database and extracting samples
****************************************************************************************************
import 		excel ${input}jne_2021_candidatos_congresales.xlsx, sheet("experiencia") first clear
br 			centro

* All in upper case
replace		centro_trabajo_org_politica=upper(centro_trabajo_org_politica)

* Replace special characters
replace		centro_trabajo_org_politica=usubinstr(centro_trabajo_org_politica,"Á","A",.)	// 33 changes
replace		centro_trabajo_org_politica=usubinstr(centro_trabajo_org_politica,"É","E",.)	// 34 changes
replace		centro_trabajo_org_politica=usubinstr(centro_trabajo_org_politica,"Í","I",.)	// 503 changes
replace		centro_trabajo_org_politica=usubinstr(centro_trabajo_org_politica,"Ó","O",.)	// 269 changes
replace		centro_trabajo_org_politica=usubinstr(centro_trabajo_org_politica,"Ú","U",.)	// 165 changes
replace		centro_trabajo_org_politica=usubinstr(centro_trabajo_org_politica,"Ñ","N",.)	// 99 changes
replace		centro_trabajo_org_politica=usubinstr(centro_trabajo_org_politica,".","",.)		// 737 changes

save 		experiencia.dta, replace

* Creating 2 random samples to train the code
forvalues 	yupa=1/2	{
use 		experiencia, clear
keep 		if tipo=="LABORAL"
sample 		2
capture 	save experiencia_s`yupa'						// Nota: no reemplazar la submuestra que ya tenemos
}


****************************************************************************************************
* 2. Coding the job clasiffications
****************************************************************************************************
// Vamos a clasificar según palabras clave, por 1) palabras completas, 2) inicio de palabras y 3) fin de palabras
// Dummy para público y privado, 
//set 		trace on		// this helps finding errors in the code

//use 		experiencia_s1, clear
//use 		experiencia_s2, clear
use 		experiencia, clear

gen 		pre_public=0
gen 		pre_private=0

* Public
	* Individuales
global 		publico "PUBLIC NACIONAL GOBIERNO REGIONAL PROVINCIAL DISTRITAL MUNICIPAL MINISTERIO SUPERINTENDENCIA AUTORIDAD CONGRESO PROYECTO PROGRAMA FEDERACION UGEL DIRESA HOSPITAL ESSALUD RENIEC MINEDU"
	* Compuestas
global 		publico1 "UNIDAD DE GESTION EDUCATIVA"
global 		publico2 "PODER JUDICIAL"
global 		publico3 "RED DE SALUD"
global 		publico4 "SEGURO SOCIAL DE SALUD"
global 		publico5 "SEGURO INTEGRAL DE SALUD"
global 		publico6 "INSTITUCION EDUCATIVA"
global 		publico7 "INSTITUTO EDUCATIVO"
global 		publico8 "UNIDAD EJECUTORA"
global 		publico9 "SITIO ARQUEOLOGICO"

	* Izquierda
global 		publico_left1 "IE "
global 		publico_left2 "IES "

	* Individuales
			capture drop aux1
gen 		aux1=0
			foreach wayta in $publico {
			replace aux1=ustrpos(centro_trabajo_org_politica,"`wayta'") if aux1==0
}
	* Compuestas
forvalues 	yupa=1/9 {
			replace aux1=ustrpos(centro_trabajo_org_politica, "${publico`yupa'}") if aux1==0
}
	* Izquierda
forvalues 	yupa=1/2 {
			local tupu=ustrlen("${publico_left`yupa'}")
			capture drop aux2
gen 		aux2=ustrleft(centro_trabajo_org_politica, `tupu')
			replace aux1=1 if aux2=="${publico_left`yupa'}"
}
	* Variable previa	
			replace pre_public=1 if aux1>0
			drop aux*
fre 		pre_public
			
* Private
	* Individuales
global		privado "PRIVAD PARTICULAR EMPRESA CONSORCIO CORPORACION COMPANIA NEGOCIO ASOCIACION ASOCIADOS SINDICATO INDEPENDIENTE SUCURSAL CLUB EIRL SRL"
	* Izquierda
global 		privado_left1 "CAJA "
global 		privado_left2 "IEP "	// Nota: colegio privado
	* Derecha
global 		privado_right1 " SA"
global 		privado_right2 " SAC"
global 		privado_right3 " LLC"

	* Individuales
			capture drop aux1
gen 		aux1=0
			foreach wayta in $privado {
			replace aux1=ustrpos(centro_trabajo_org_politica,"`wayta'") if aux1==0
}
	* Izquierda
forvalues 	yupa=1/2 {
			local tupu=ustrlen("${privado_left`yupa'}")
			capture drop aux2
gen 		aux2=ustrleft(centro_trabajo_org_politica, `tupu')
			replace aux1=1 if aux2=="${privado_left`yupa'}"
}
	* Derecha
forvalues 	yupa=1/3 {
			local tupu=ustrlen("${privado_right`yupa'}")
			capture drop aux2
gen 		aux2=ustrright(centro_trabajo_org_politica, `tupu')
			replace aux1=1 if aux2=="${privado_right`yupa'}"
}
	* Variable previa	
			replace pre_private=1 if aux1>0
			drop aux*
fre 		pre_private

* Clasificación
gen 		public=(pre_public==1 & pre_private==0)
			fre public
br 			centro pre*	public

****************************************************************************************************
* 3. Mannually correcting
****************************************************************************************************
replace 	public=1 if tipo=="CARGO_ELECCIONES"

* From sample 1
global 		m_public1 "UNIVERSIDAD DE CHICLAYO"

global 		m_private1 "PARTIDO NACIONALISTA"
global 		m_private2 "RESTAURACION NACIONAL"

* From sample 2
global 		m_public2 "UNIVERSIDAD SANTIAGO ANTUNEZ DE MAYOLO"
global 		m_public3 "SOCIEDAD DE BENEFICIENCIA DE LIMA METROPOLITANA"

	* Compuestas
forvalues 	yupa=1/3 {
			capture drop aux1
			gen aux1=ustrpos(centro_trabajo_org_politica, "${m_public`yupa'}")
			replace public=1 if aux1>0
}
forvalues 	yupa=1/2 {
			capture drop aux1
			gen aux1=ustrpos(centro_trabajo_org_politica, "${m_private`yupa'}")
			replace public=0 if aux1>0
}
	* Check
		* Cargo elecciones
			br if tipo=="CARGO_ELECCIONES" & aux1>0
			br if tipo=="LABORAL" & aux1>0
replace 	public=1 if tipo=="CARGO_ELECCIONES"	// De nuevo porque algunos ponen el cargo con el nombre del partido
		* Cargo partidario
			br if public==1 & tipo=="CARGO_PARTIDARIO"
replace 	public=0 if tipo=="CARGO_PARTIDARIO"
			
			drop aux1 pre*
save 		experiencia_pre_classified, replace 		// versión previa, luego hay que corregir todo manual
export 		delimited experiencia_pre_classified, replace
export 		excel experiencia_pre_classified, replace

* Correcting the rest
use 		experiencia_pre_classified, clear
rename 		public public_pre
gen 		flag=0
clonevar 	public=public_pre
br 			centro tipo ocupacion public_pre flag

	* Público
		* Oferta de salud - de buscar uno por uno en: http://app20.susalud.gob.pe:8080/registro-renipress-webapp/listadoEstablecimientosRegistrados.htm?action=mostrarBuscar#no-back-button
replace 	public==1 if centro_trabajo_org_politica==="CENTRO DE SALUD DE VILLA PRIMAVERA"
replace 	public==1 if centro_trabajo_org_politica==="CENTRO DE SALUD SANTA TERESITA"
replace 	public==1 if centro_trabajo_org_politica==="OFICINA DE OPERACIONES SALUD ALTO MAYO"
replace 	public==1 if centro_trabajo_org_politica==="POLICLINICO SANIDAD PNP"
replace 	public==1 if centro_trabajo_org_politica==="CLAS AGUAS VERDES"
replace 	public==1 if centro_trabajo_org_politica==="ESTABLECIMIENTO DE SALUD I 3 TACALA MINSA"
replace 	public==1 if centro_trabajo_org_politica==="PUESTO DE SALUD TAQUILE"
replace 	public==1 if centro_trabajo_org_politica==="PUESTO DE SALUD PUERTO PUNO"
replace 	public==1 if centro_trabajo_org_politica==="CENTRO DE SALUD COLLIQUE III ZONA"
replace 	public==1 if centro_trabajo_org_politica==="CENTRO DE SALUD  SAN JUAN DE AMANCAES  - MINSA"
replace 	public==1 if centro_trabajo_org_politica==="DIRECCION DE SALUD APURIMAC II"
replace 	public==1 if centro_trabajo_org_politica==="CENTRO DE SALUD SAN CLEMENTE"
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""

		* Colegios - de buscar uno por uno en: http://sigmed.minedu.gob.pe/mapaeducativo/
replace 	public==1 if centro_trabajo_org_politica==="IE ISABEL CHIMPO OCLLO UGEL 02" // Nota: en realidad es "CHIMPU"
replace 	public==1 if centro_trabajo_org_politica==="IEE MARISCAL LUZURIAGA CASMA"
replace 	public==1 if centro_trabajo_org_politica==="ESCUELA DE EDUCACION SUPERIOR PEDAGOGICO LA SALLE DE URUBAMBA"
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""

		* Otros - de buscar uno por uno
replace 	public==1 if centro_trabajo_org_politica==="CORTE SUPERIOR DE JUSTICIA DE ANCASH - PJ"
replace 	public==1 if centro_trabajo_org_politica==="PROMPERU"
replace 	public==1 if centro_trabajo_org_politica==="FUERZA AEREA DEL PERU"
replace 	public==1 if centro_trabajo_org_politica==="EJERCITO DEL PERU - OALE"
replace 	public==1 if centro_trabajo_org_politica==="AGENCIA DE PROMOCION DE LA INVERSION PRIVADA - PROINVERSION"
replace 	public==1 if centro_trabajo_org_politica==="COFOPRI"
replace 	public==1 if centro_trabajo_org_politica==="INDECOPI"
replace 	public==1 if centro_trabajo_org_politica==="MININTER"
replace 	public==1 if centro_trabajo_org_politica==="DIERCCION GENERAL DE NTELIGENCIA - MININTER"
replace 	public==1 if centro_trabajo_org_politica==="MINDEF - EJERCITO DEL PERU"
replace 	public==1 if centro_trabajo_org_politica==="INSTITUTO PERUANO DEL DEPORTE"
replace 	public==1 if centro_trabajo_org_politica==="SERPAR"
replace 	public==1 if centro_trabajo_org_politica==="SERPAR/ SERVICIOS DE PARQUES DE LIMA - MML"
replace 	public==1 if centro_trabajo_org_politica==="FONCODES"
replace 	public==1 if centro_trabajo_org_politica==="PERUPETRO SA"
replace 	public==1 if centro_trabajo_org_politica==="DIRECCION DESCONCENTRADA DE CULTURA CUSCO-DDC-CUSCO"
replace 	public==1 if centro_trabajo_org_politica==="CENTRAL DE COMUNIDADES NATIVAS MATSIGENKAS"
replace 	public==1 if centro_trabajo_org_politica==="UNIDAD DE GESTION EDUCATIVO LOCAL SAN MARTIN"
replace 	public==1 if centro_trabajo_org_politica==="RED SALUD PACIFICO NORTE ANCASH"
replace 	public==1 if centro_trabajo_org_politica==="SENATI"
replace 	public==1 if centro_trabajo_org_politica==="EMPRESA REGIONAL DE SERVICIO PUBLICO DE ELECTRICIDAD"
replace 	public==1 if centro_trabajo_org_politica==="PRESIDENCIA DEL CONSEJO DE MINISTROS"
replace 	public==1 if centro_trabajo_org_politica==="AGRO RURAL"
replace 	public==1 if centro_trabajo_org_politica==="EMPRESA MUNICIPAL DE MERCADOS - EMMSA"
replace 	public==1 if centro_trabajo_org_politica==="EMELIMA - EMPRESA MUNICIPAL INMOBILIARIA DE LIMA SA"
replace 	public==1 if centro_trabajo_org_politica==="OFICINA DE NORMALIZACION PREVISIONAL - ONP"
replace 	public==1 if centro_trabajo_org_politica==="SEDAPAL"
replace 	public==1 if centro_trabajo_org_politica==="DESPACHO PRESIDENCIAL"
replace 	public==1 if centro_trabajo_org_politica==="MIMP"
replace 	public==1 if centro_trabajo_org_politica==="CENTRO DE ATENCION RESIDENCIAL SANTO DOMINGO SABIO TACNA - INABIF-MIMP"
replace 	public==1 if centro_trabajo_org_politica==="SUNARP"
replace 	public==1 if centro_trabajo_org_politica==="SUNARP CUSCO"
replace 	public==1 if centro_trabajo_org_politica==="MIDIS"
replace 	public==1 if centro_trabajo_org_politica==="CENTRO POBLADO DE VILLA LOPEZ" & ocupacion_profesion_cargo=="ALCALDESA"
replace 	public==1 if centro_trabajo_org_politica==="INSTITUTO DE ESTADISTICA E INFORMATICA"
replace 	public==1 if centro_trabajo_org_politica==="ASOCIACION DE MUNICIPALIDADES DEL PERU"
replace 	public==1 if centro_trabajo_org_politica==="AGRO RURAL"
replace 	public==1 if centro_trabajo_org_politica==="BANCO DE LA NACION"
replace 	public==1 if centro_trabajo_org_politica==="ONP"
replace 	public==1 if centro_trabajo_org_politica==="SERVICIO NACIONAL DE CAPACITACION PARA LA INDUSTRIA DE LA CONSTRUCCION- SENCICO-"
replace 	public==1 if centro_trabajo_org_politica==="MARINA DE GUERRA DEL PERU"
replace 	public==1 if centro_trabajo_org_politica==="FONCODES"
replace 	public==1 if centro_trabajo_org_politica==="UNIDAD TERRITORIAL FONCODES AYACUCHO"
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
		
		* Errores
replace 	public==1 if centro_trabajo_org_politica==="MINUCIPALIDAD DE LA VICTORIA"
			replace centro_trabajo_org_politica="MUNICIPALIDAD DE LA VICTORIA" if centro_trabajo_org_politica==="MINUCIPALIDAD DE LA VICTORIA"
replace 	public==1 if centro_trabajo_org_politica==="MINISTERO DE DEFENSA - EJERCITO DEL PERU"
			replace centro_trabajo_org_politica="MINISTERIO DE DEFENSA - EJERCITO DEL PERU" if centro_trabajo_org_politica==="MINISTERO DE DEFENSA - EJERCITO DEL PERU"
replace 	public==1 if centro_trabajo_org_politica==="MINOISTERIO DE AGRICULTURA Y RIEGO"
			replace centro_trabajo_org_politica="MINISTERIO DE AGRICULTURA Y RIEGO" if centro_trabajo_org_politica==="MINOISTERIO DE AGRICULTURA Y RIEGO"
replace 	public==1 if centro_trabajo_org_politica==="DIRECCION DE TRANSPORTES Y COMUNICACIONES"
			replace centro_trabajo_org_politica="DIRECCION REGIONAL DE TRANSPORTES Y COMUNICACIONES" if centro_trabajo_org_politica==="DIRECCION DE TRANSPORTES Y COMUNICACIONES"
replace 	public==1 if centro_trabajo_org_politica==="DIRECCION REGONAL DE SALUD DE LORETO - UE 407"
			replace centro_trabajo_org_politica="DIRECCION REGIONAL DE SALUD DE LORETO - UE 407" if centro_trabajo_org_politica==="DIRECCION REGONAL DE SALUD DE LORETO - UE 407"
replace 	public==1 if centro_trabajo_org_politica==="HODPITAL DE SUPE MINSA"
			replace centro_trabajo_org_politica="HOSPITAL DE SUPE MINSA" if centro_trabajo_org_politica==="HODPITAL DE SUPE MINSA"
replace 	public==1 if centro_trabajo_org_politica===""
			replace centro_trabajo_org_politica="" if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
			replace centro_trabajo_org_politica="" if centro_trabajo_org_politica===""
replace 	public==1 if centro_trabajo_org_politica===""
			replace centro_trabajo_org_politica="" if centro_trabajo_org_politica===""

	* Privado
replace 	public==0 if centro_trabajo_org_politica==="ONG PLAN INTERNACIONAL"
replace 	public==0 if centro_trabajo_org_politica==="ONG  PLAN INTERNACIONAL"
replace 	public==0 if centro_trabajo_org_politica==="RED BUEN GOBIERNO"
replace 	public==0 if centro_trabajo_org_politica==="PLAN  INTERNACIONAL PERU"
replace 	public==0 if centro_trabajo_org_politica==="INSTITUTO DE ESTUDIOS PERUANOS"
replace 	public==0 if centro_trabajo_org_politica==="ABACUS AGENCIA DE ADUANAS - LOGISTICA INTERNACIONAL"
replace 	public==0 if centro_trabajo_org_politica===""
replace 	public==0 if centro_trabajo_org_politica===""
replace 	public==0 if centro_trabajo_org_politica===""
replace 	public==0 if centro_trabajo_org_politica===""
replace 	public==0 if centro_trabajo_org_politica===""
replace 	public==0 if centro_trabajo_org_politica===""

		* Errores
replace 	public==0 if centro_trabajo_org_politica===""
replace 	public==0 if centro_trabajo_org_politica===""
replace 	public==0 if centro_trabajo_org_politica===""

	* Flag
replace 	flag==1 if centro_trabajo_org_politica==="CENTRO DE SALUD LA CARRETERA KM 1 1/2"
replace 	flag==1 if centro_trabajo_org_politica==="CENTRO DE SALUD LA CARRETERA 11/2"
replace 	flag==1 if centro_trabajo_org_politica==="UNIVERSIDAD PERUANA DEL NORTE"
replace 	flag==1 if centro_trabajo_org_politica==="UNP"

		* COLES?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA TUPAC AMARU"	// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE INMACULADA CONCEPCION"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA MARISCAL OSCAR R BENAVIDES"	// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="EEP MARIA DE LOS ANGELES RD 1539 - 2215"	// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP MARIA DE LOS ANGELES RD 1539 - 2215"	// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA CARLOS AUGUSTO SALAVERRY"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA NINO JESUS DE PRAGA"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="COLEGIO DANIEL BECERRA OCAMPO"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP NINO JESUS TERREMOTITO"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP EL MERCEDARIO  RVDO PADRE ELEUTERIO ALARCON BEJARANO"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP HAPPY CHILDRENS"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA "SANTO DOMINGO""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP JESUS ES MI MAESTRO"			// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP SAN JOSE"			// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP TUPAC AMARU"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="ISTP "CARLOS SALAZAR ROMERO""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP JUAN VALER SANDOVAL"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE VIRGEN DE FATIMA"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="JARDIN DE NINO  015"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE SAGRADO CORAZON DE JESUS"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUTO DE EDUCACION SUPERIOR PEDAGOGICO PUBLICO HUARI"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA 86777 - CRISTO REY"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA 86052 DE ISCOG"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA 86405 DE UCHUHUAYTA"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA 439 DE CATAYOC"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP N° 62172 "JORGE ALFONSO VASQUEZ REATEGUI""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEI N° 212 NINO JESUS"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE DE APLICACION NUESTRA SENORA DE LOURDES"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="COLEGIO SALESIANO SAN JUAN BOSCO DE AYACUCHO"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE N° 7012 "JESUS DE LA MISERICORDIA""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="PRITE 01 TUMBES"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTIUTO EDUCATIVO SUPERIOR TECNOLOGICO PUBLICO CIRO ALREGRIA BAZAN"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA 32925 - RENE E GUARDIAN RAMIREZ"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE  15014 M HIDALGO CARNERO"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA JOSE MARIA ARGUEDAS MILPO"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE JOSE CAYETANO HEREDIA - CATACAOS"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IE SENOR DE LOS MILAGROS 11011"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="CUNA JARDIN CEDIF LOS CABITOS"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA INICIAL 197 ORFEON"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="INSTITUCION EDUCATIVA INICIAL N 349 CAMBAYA"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica==="IEP SAN JUAN EL BAUTISTA"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?

		* SALUD
replace 	flag==1 if centro_trabajo_org_politica==="CENTRO DE SALUD SANTA ROSA - CUSCO"				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?
replace 	flag==1 if centro_trabajo_org_politica===""				// publica o privada?

**linea 1358 me quede