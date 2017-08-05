/*
#######################################################################################################################
	Christophe Pages (http://www.c-pages.fr) 	
##########################################################################################################################
	
	URBA
	Générateur de ville
	
##########################################################################################################################
	
	Fichier principale
	
##########################################################################################################################

	todo:
	
##########################################################################################################################
	changelog:
	*v0.1 - [27/07/2017] -----------------------------------------------------------------------------
	- Mise en place globale 
	
########################################################################################################################*/



(
	
----- scripts globaux -------------
include "$userScripts\cp - GLOBAL\UI.ms"
include "$userScripts\cp - GLOBAL\DragDialog.ms"
include "$userScripts\cp - GLOBAL\Debug.ms"
	
----- scripts externes -------------
include "$userScripts\cp - Urba\Urba - Construction.ms"
include "$userScripts\cp - Urba\Urba - Edit.ms"


------------------------------------------------------------------------------
----------	FENETRE								 -------------------------
------------------------------------------------------------------------------
rollout roll_urba  "urba " width:296 height:296
(
	------------ DEBUG	----------------------------------------------------------------------------------
	local m_debug = true
	local m_dbgPrefix ="urba rollout"
	fn debug 	_txt  var:	 param:    =(
		if m_debug do ::debuger 	_txt  	var:var	 param:param	prefix:m_dbgPrefix
	)

	
	
	
	------------  Membres	----------------------------------------------------------------------------------
	---- Pointeurs ----
	local m_prt				---- pointeur vers la structure de controle ----
	local m_prefs			---- pointeur vers les preferences "Fenetre"de labib ----
	
	---- Structures ----
	local m_drag			---- la structure gerant le drag de la fenetre ----
	
	--- ctro des imgtags ---
	local m_titre
	
	
	
	fn shape_filt 		obj = superclassof obj == shape
	------------  UI	----------------------------------------------------------------------------------		
	
	ImgTag 'ui_titre' "" pos:[16,4] width:66 height:18 align:#left
	
	---- le bouton pour fermer la fenetre ----
	ImgTag ui_btnFermer "X" pos:[276,0] width:20 height:20 toolTip:"Fermer" style:#bmp_center
	
	
	
	pickbutton 'btn_shape' "Shape" pos:[19,34] width:266 height:23 align:#left autoDisplay:true filter:shape_filt
	button 'btn_generer' "Générer" pos:[24,241] width:259 height:38 align:#left
	radioButtons 'rdo1' "" pos:[27,125] width:125 height:16 labels:#("Par surfaces") align:#left
	spinner 'spn_etagesMin' "" pos:[156,76] width:121 height:16 range:[0,100,1] type:#integer scale:1 align:#left
	label 'lbl1' "Etages min. :" pos:[28,76] width:94 height:18 align:#left
	
	
	spinner 'spn_etagesMax' "" pos:[156,96] width:121 height:16 range:[0,100,5] type:#integer scale:1 align:#left
	label 'lbl2' "Etages max. :" pos:[28,96] width:94 height:18 align:#left
	------------  Fonctions	----------------------------------------------------------------------------------
	
	fn reagencer taille: 	=(
		
		Local LargeurBtn = 20
		
		if taille == unsupplied do taille = [ roll_urba.width, roll_urba.height ]
		ui_btnFermer.pos.x		=	taille.x - ( LargeurBtn )
		
	)
	
	
	
	---- Gere l'état du bouton  fermer -----
	fn etatBtnFermer		_etat =(
		case _etat of (
			#Repos : 	ui_btnFermer.bitmap = m_prt.m_icos_fermer[1]
			#Survol : 	ui_btnFermer.bitmap = m_prt.m_icos_fermer[2]
			#Press : 	ui_btnFermer.bitmap = m_prt.m_icos_fermer[3]
		)
	)
	
	
	
	
	---- Initialisation de la fenetre  -----
	fn initialiser  ptr_parent= (
		
		debug "initialiser"
		
		-- se raccrocher à labib --
		m_prt = ptr_parent
		
		-- le titre --
		m_titre 	= str_label 	m_ui:ui_titre			m_texte:m_prt.m_titre
		m_titre.setCouleur 		m_prt.col_fenetreTxt
		m_titre.setCouleurFond 	m_prt.col_fenetreFond
		
		-- le drag --
		m_drag 		= str_drag 	m_prt:roll_urba
		
		-- le bouton fermer --
		ui_btnFermer.bitmap = m_prt.m_icos_fermer[1]	
		b_initialisation = true
	)
	
	------------  Evenements	----------------------------------------------------------------------------------
	---- Fenetre -----
	on roll_urba moved			_pos 	do	m_prt.m_pos	= _pos	
	on roll_urba resized			_taille 	do	reagencer ()
	
	---- Drag ----
	on roll_urba lbuttondown	_pos 	do	m_drag.demarrer ()
	on roll_urba lbuttonup 		_pos 	do	m_drag.arreter ()
	on roll_urba mouseMove 	_pos 	do	m_drag.suivreSouris ()
	
	---- Bouton fermer -----
	on 	ui_btnFermer	mouseover 		do 	etatBtnFermer #Survol
	on 	ui_btnFermer	mouseout 			do 	etatBtnFermer #Repos
	on 	ui_btnFermer	mousedown 		do 	etatBtnFermer #Press
	on 	ui_btnFermer	mouseup			do 	etatBtnFermer #Repos
	on 	ui_btnFermer 	click 				do 	m_prt.fermer ()
	
	--- edition ----
	on btn_shape picked obj 				do	m_prt.edit.preparer obj
	

)
	
------------------------------------------------------------------------------
----------	Structure								 -------------------------
------------------------------------------------------------------------------
struct str_urba (
	
	------------ DEBUG	----------------------------------------------------------------------------------
	m_debug = true,
	m_dbgPrefix ="urba",
	fn debug 	_txt  var:	 param:    =(
		if m_debug do ::debuger 	_txt  	var:var	 param:param	prefix:m_dbgPrefix
	),
	
	
	------------  Membres	----------------------------------------------------------------------------------
	public
		
		---- pointeurs ----
		m_dialog				= roll_urba ,		---- le rollout ----
		
		---- props de la fenetre -----
		m_titre 				= "Labib | urba ",
		m_pos 					= [100,100],
		m_taille 				= [300, 300],
		m_estOuvert 		= false,
		
		--- ui libre de labib -----------	
	/* 	--	Couleurs ui sombre -----
		col_fenetreFond			= color 68 68 68, 		---- MAX 	----
		col_fenetreTxt			= color 230  230 230, 	----  		----
	 */
		--	Couleurs ui claire -----
		col_fenetreFond			= color 200 200 200, 		---- MAX 	----
		col_fenetreTxt			= color 0  0 0, 	----  		----
		
		ico_btnFermer_R	=	"$userScripts\cp - GLOBAL\ico\ico_fermer_grisClaire_R.jpg",
		ico_btnFermer_S	=	"$userScripts\cp - GLOBAL\ico\ico_fermer_grisClaire_S.jpg",
		ico_btnFermer_P	=	"$userScripts\cp - GLOBAL\ico\ico_fermer_grisClaire_P.jpg", 
	
		m_icos_fermer= #( 	openbitmap ico_btnFermer_R, openbitmap ico_btnFermer_S, openbitmap ico_btnFermer_P ),
		
		
		---- structures ----
		edit 			= str_urba_edit (),
		contruire 	= str_urba_construction (),
		
		
		------------  Fonctions	----------------------------------------------------------------------------------
	public
		fn estOuvert = m_estOuvert,
		fn ouvrir =(
			debug "ouvrir"
			m_estOuvert 		= true
			
			---- creation de la fenetre ----
			createDialog m_dialog 	fgcolor:			col_fenetreFond 	\
											style:				#(#style_resizing) \
											pos:					m_pos	
-- 											lockHeight:			true	\
-- 											lockWidth:			true	 \	
			
			---- initialisation de la fenetre ----
			m_dialog.initialiser 	this
	
		),
		
		fn fermer  silence:false =(		---- silence : fermer sans modifier l'état des preferences ---	
			debug "fermer"
			m_estOuvert 		= false
			---- maj des preferences ----	
			if not silence do (
			)
			
			---- fermer la fenêtre ----
			try destroydialog m_dialog catch ()
		),
		
		fn toggleOuverture =(
			
			if m_estOuvert
				then fermer ()
				else	ouvrir ()
			
		),
		
		------------  Evenements	----------------------------------------------------------------------------------
	on create do (
		debug "Initialiser"
	)
) -- fin struct urba -----


	global urba  	=	str_urba () --	m_labib:Labib
	
	urba



)