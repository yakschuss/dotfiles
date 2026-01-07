# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
.autocomplete:__main__ () {
	zmodload -Fa zsh/files b:zf_mkdir b:zf_rm
	zmodload -F zsh/parameter p:functions
	zmodload -F zsh/system p:sysparams
	zmodload -F zsh/zleparameter p:widgets
	zmodload -Fa zsh/zutil b:zstyle
	builtin autoload +X -Uz add-zsh-hook zmathfunc
	zmathfunc
	typeset -ga _autocomplete__comp_opts=(localoptions NO_banghist) 
	typeset -ga _autocomplete__ctxt_opts=(completealiases completeinword) 
	typeset -ga _autocomplete__mods=(compinit config widgets key-bindings recent-dirs async) 
	typeset -gU FPATH fpath=(~autocomplete/Completions $fpath[@]) 
	local -P xdg_data_home=${XDG_DATA_HOME:-$HOME/.local/share} 
	local -P zsh_data_dir=$xdg_data_home/zsh 
	[[ -d $zsh_data_dir ]] || zf_mkdir -pm 0700 $zsh_data_dir
	local -P old_logdir=$xdg_data_home/zsh-autocomplete/log 
	[[ -d $old_logdir ]] && zf_rm -fr -- $old_logdir
	local -P logdir=${XDG_STATE_HOME:-$HOME/.local/state}/zsh-autocomplete/log 
	local -P bug= 
	for bug in ${logdir} ${logdir:h}
	do
		[[ -d $bug ]] || zf_rm -f $bug
	done
	zf_mkdir -p -- $logdir
	hash -d autocomplete-log=$logdir
	local -Pa older_than_a_week=($logdir/*(Nmd+7)) 
	(( $#older_than_a_week[@] )) && zf_rm -f -- $older_than_a_week[@]
	typeset -g _autocomplete__log=${logdir}/${(%):-%D{%F}}.log 
	typeset -g _autocomplete__ps4=$'%D{%T.%.} %e\t%N\t%I\t%? %(1_,%_ ,)' 
	local -P zsh_cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh 
	[[ -d $zsh_cache_dir ]] || zf_mkdir -pm 0700 $zsh_cache_dir
	local -P mod= 
	for mod in $_autocomplete__mods
	do
		builtin zstyle -T ":autocomplete:$mod" enabled && .autocomplete:$mod "$@"
		unfunction .autocomplete:$mod
	done
	add-zsh-hook precmd ${0}:precmd
	typeset -gaU precmd_functions=(${0}:precmd $precmd_functions) 
	${0}:precmd () {
		0=${(%):-%N} 
		add-zsh-hook -d precmd $0
		unfunction $0
		() {
			emulate -L zsh
			setopt $_autocomplete__func_opts[@]
			if builtin zstyle -L zle-hook types > /dev/null
			then
				local -P hook= 
				for hook in zle-{isearch-{exit,update},line-{pre-redraw,init,finish},history-line-set,keymap-select}
				do
					[[ -v widgets[$hook] && $widgets[$hook] == user:_zsh_highlight_widget_orig-s*-r<->-$hook ]] && builtin zle -N $hook azhw:$hook
				done
			fi
		}
		local -P mod= 
		for mod in $_autocomplete__mods
		do
			mod=.autocomplete:${mod}:precmd 
			if [[ -v functions[$mod] ]]
			then
				$mod
				unfunction $mod
			fi
		done
		true
	}
}
.autocomplete:__main__:precmd () {
	0=${(%):-%N} 
	add-zsh-hook -d precmd $0
	unfunction $0
	() {
		emulate -L zsh
		setopt $_autocomplete__func_opts[@]
		if builtin zstyle -L zle-hook types > /dev/null
		then
			local -P hook= 
			for hook in zle-{isearch-{exit,update},line-{pre-redraw,init,finish},history-line-set,keymap-select}
			do
				[[ -v widgets[$hook] && $widgets[$hook] == user:_zsh_highlight_widget_orig-s*-r<->-$hook ]] && builtin zle -N $hook azhw:$hook
			done
		fi
	}
	local -P mod= 
	for mod in $_autocomplete__mods
	do
		mod=.autocomplete:${mod}:precmd 
		if [[ -v functions[$mod] ]]
		then
			$mod
			unfunction $mod
		fi
	done
	true
}
.autocomplete:async:clear () {
	unset curcontext _autocomplete__isearch
	.autocomplete:async:reset-context
	builtin zle -Rc
	return 0
}
.autocomplete:async:compadd () {
	local -Pi _ret_=1 
	local -P _displ_name_= _matches_name_= 
	local -A _opts_=() 
	local -a _displ_=() _dopt_=() _groupname_=() _matches_=() 
	zparseopts -A _opts_ -E -- D: E: O: X: x: d+:=_dopt_ l
	if [[ -v _opts_[-x] && $# -eq 2 ]]
	then
		builtin compadd "$@"
		return
	fi
	local -Pi _avail_list_lines_=$((
      max( 0, _autocomplete__max_lines - 1 - ${${_opts_[(i)-[Xx]]}:+1} - compstate[list_lines] )
  )) 
	if (( funcstack[(I)_describe] ))
	then
		if [[ -n $_opts_[-D] ]]
		then
			_displ_name_=$_opts_[-D] 
			_matches_name_=$_opts_[-O] 
			if (( _autocomplete__described_lines >= _autocomplete__max_lines ))
			then
				set -A $_displ_name_
				return 1
			else
				builtin compadd "$@"
				_ret_=$? 
				_displ_=(${(@PA)_displ_name_}) 
				_matches_=(${(@PA)_matches_name_}) 
				if (( $#_displ_[@] ))
				then
					local -PaU _uniques_=(${_displ_[@]#*:}) 
					local -P _lines_too_many=$(( -1 * ( _avail_list_lines_ - _autocomplete__described_lines - $#_uniques_[@] ) )) 
					(( _lines_too_many > 0 )) && shift -p $_lines_too_many $_displ_name_ $_matches_name_
					(( _autocomplete__described_lines += ${(@PA)#_displ_name_} ))
				fi
				return _ret_
			fi
		elif [[ -n $_opts_[-E] ]]
		then
			(( _autocomplete__described_lines = 0 ))
			builtin compadd "$@"
			return
		fi
		(( _autocomplete__described_lines = 0 ))
	fi
	if [[ -n $_opts_[-D]$_opts_[-O] ]]
	then
		builtin compadd "$@"
		return
	fi
	[[ -v _autocomplete__partial_list ]] && return 1
	local -Pi _resulting_list_lines="$(
      builtin compadd "$@"
      print -nr -- $compstate[list_lines]
  )" 
	local -Pi _new_list_lines_=$(( _resulting_list_lines - $compstate[list_lines] )) 
	local -Pi _remaining_list_lines=$(( _avail_list_lines_ - _new_list_lines_ )) 
	(( _remaining_list_lines <= 0 )) && .autocomplete:async:compadd:disable
	if (( _remaining_list_lines >= 0 ))
	then
		builtin compadd "$@"
		return
	fi
	_displ_name_=$_dopt_[2] 
	[[ -n $_displ_name_ ]] && local -a _Dopt_=(-D $_displ_name_) 
	builtin compadd -O _matches_ $_Dopt_ "$@"
	if [[ -z $_displ_name_ ]]
	then
		_displ_=("$_matches_[@]") 
		_dopt_=(-d _displ_) 
		_displ_name_=_displ_ 
	fi
	local -Pi _nmatches_per_line_=$(( 1.0 * $#_matches_ / _new_list_lines_ )) 
	if (( _nmatches_per_line_ < 1 ))
	then
		_nmatches_per_line_=1 
		_dopt_=(-l "$_dopt_[@]") 
		set -A $_displ_name_ ${(@r:COLUMNS-1:)${(PA)_displ_name_}[@]//$'\n'/\n}
	fi
	local -Pi _nmatches_that_fit_=$(( _avail_list_lines_ * _nmatches_per_line_ )) 
	local -Pi _nmatches_to_remove_=$(( $#_matches_ - _nmatches_that_fit_ )) 
	(( _nmatches_to_remove_ > 0 )) && shift -p $_nmatches_to_remove_ _matches_ $_displ_name_
	_autocomplete__compadd_opts_len "$@"
	builtin compadd $_dopt_ -a "$@[1,?]" _matches_
}
.autocomplete:async:compadd:disable () {
	typeset -g _autocomplete__partial_list=$curtag 
	comptags () {
		false
	}
}
.autocomplete:async:complete () {
	.autocomplete:zle-flags $LASTWIDGET || return 0
	(( KEYS_QUEUED_COUNT || PENDING )) && return
	{
		if [[ -v DEBUG ]]
		then
			set -x -o localoptions
			local +h PS4=$_autocomplete__ps4 
		fi
		[[ -v _FAST_MAIN_CACHE ]] && _zsh_highlight
		typeset -g _autocomplete__region_highlight=("$region_highlight[@]") 
		if [[ -v ZSH_AUTOSUGGEST_IGNORE_WIDGETS ]] && (( ZSH_AUTOSUGGEST_IGNORE_WIDGETS[(I)$LASTWIDGET] ))
		then
			unset POSTDISPLAY
		fi
		[[ -v _autocomplete__lbuffer || -v _autocomplete__rbuffer ]] && return 0
		if [[ $LASTWIDGET == (autosuggest-suggest|.autocomplete:async:*:fd-widget) ]]
		then
			return 0
		fi
		if (( REGION_ACTIVE )) || [[ -v _autocomplete__isearch && $LASTWIDGET == *(incremental|isearch)* ]]
		then
			builtin zle -Rc
			return 0
		fi
		[[ $LASTWIDGET == (_complete_help|(|.)(describe-key-briefly|(|.)(|reverse-)menu-complete|what-cursor-position|where-is)) ]] && return
		[[ $KEYS == ([\ -+*]|$'\e\t') ]] && builtin zle -Rc
		.autocomplete:async:wait
		set +x
	} 2>>| $_autocomplete__log
	return 0
}
.autocomplete:async:complete:fd-widget () {
	{
		if [[ -v DEBUG ]]
		then
			local +h PS4=$_autocomplete__ps4 
			set -x -o localoptions
			functions -T .autocomplete:async:list-choices:completion-widget
		fi
		local -i fd=$1 
		{
			builtin zle -F $fd
			if ! .autocomplete:zle-flags
			then
				.autocomplete:async:reset-state
				return 0
			fi
			if ! .autocomplete:async:same-state
			then
				.autocomplete:async:start
				return 0
			fi
			.autocomplete:async:reset-state
			local -a reply=() 
			IFS=$'\0' read -rAu $fd
			shift -p reply
		} always {
			exec {fd}<&-
		}
		setopt $_autocomplete__comp_opts[@]
		[[ -n $curcontext ]] && setopt $_autocomplete__ctxt_opts[@]
		if ! builtin zle ._list_choices -w "$reply[@]" 2>>| $_autocomplete__log
		then
			typeset -g region_highlight=("$_autocomplete__region_highlight[@]") 
			[[ -v functions[_zsh_autosuggest_highlight_apply] ]] && _zsh_autosuggest_highlight_apply
			builtin zle -R
		fi
		.autocomplete:async:reset-state
		set +x
		return 0
	} 2>>| $_autocomplete__log
}
.autocomplete:async:history-incremental-search () {
	if [[ $curcontext == $WIDGET* ]]
	then
		unset curcontext
	else
		typeset -g curcontext=${WIDGET}::: 
	fi
	.autocomplete:async:complete
}
.autocomplete:async:isearch-exit () {
	.autocomplete:zle-flags $LASTWIDGET
	unset _autocomplete__isearch
}
.autocomplete:async:isearch-update () {
	typeset -gi _autocomplete__isearch=1 
}
.autocomplete:async:list-choices:completion-widget () {
	if [[ $1 != <1-> ]]
	then
		compstate[list]= 
		return
	fi
	.autocomplete:async:sufficient-input || return 2
	compstate[insert]= 
	compstate[old_list]= 
	compstate[pattern_insert]= 
	.autocomplete:async:list-choices:main-complete
	unset MENUSELECT MENUMODE
	compstate[insert]= 
	_lastcomp[insert]= 
	compstate[pattern_insert]= 
	_lastcomp[pattern_insert]= 
	if [[ -v _autocomplete__partial_list ]]
	then
		builtin compadd -J -last- -x '%F{black}%K{12}(MORE)%f%k'
		_lastcomp[list_lines]=$compstate[list_lines] 
	fi
	[[ -v DEBUG ]] && typeset -m _lastcomp >&2
	return 2
} 2>>| $_autocomplete__log
.autocomplete:async:list-choices:main-complete () {
	local -i _autocomplete__max_lines=0 _autocomplete__described_lines=0 
	if [[ $curcontext == *history-* ]]
	then
		setopt $_autocomplete__func_opts[@]
		autocomplete:_main_complete:new - history-lines _autocomplete__history_lines
	else
		{
			() {
				emulate -L zsh
				setopt $_autocomplete__func_opts[@]
				local curcontext=list-choices::: 
				[[ -v functions[compadd] ]] && functions[autocomplete:async:compadd:old]="$functions[compadd]" 
				functions[compadd]="$functions[.autocomplete:async:compadd]" 
				[[ -v VERBOSE ]] && functions -T compadd _describe
			} "$@"
			.autocomplete:async:list-choices:max-lines 16
			autocomplete:_main_complete:new "$@"
		} always {
			unfunction compadd comptags 2> /dev/null
			if [[ -v functions[autocomplete:async:compadd:old] ]]
			then
				functions[compadd]="$functions[autocomplete:async:compadd:old]" 
				unfunction autocomplete:async:compadd:old
			fi
		}
	fi
}
.autocomplete:async:list-choices:max-lines () {
	local -Pi max_lines=0 
	builtin zstyle -s ":autocomplete:${curcontext}:" list-lines max_lines || max_lines=$1 
	_autocomplete__max_lines=$(( min( max_lines, LINES - BUFFERLINES - 1 ) )) 
}
.autocomplete:async:precmd () {
	[[ -v ZSH_AUTOSUGGEST_IGNORE_WIDGETS ]] && ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(history-incremental-search-backward .autocomplete:async:complete:fd-widget) 
	builtin zle -N .autocomplete:async:pty:zle-widget
	builtin zle -C .autocomplete:async:pty:completion-widget list-choices .autocomplete:async:pty:completion-widget
	builtin zle -N .autocomplete:async:complete:fd-widget
	builtin zle -N .autocomplete:async:wait:fd-widget
	builtin zle -C ._list_choices list-choices .autocomplete:async:list-choices:completion-widget
	builtin zle -N history-incremental-search-backward .autocomplete:async:history-incremental-search
	add-zle-hook-widget line-init .autocomplete:async:reset-context
	add-zle-hook-widget line-pre-redraw .autocomplete:async:complete
	add-zle-hook-widget line-finish .autocomplete:async:clear
	add-zle-hook-widget isearch-update .autocomplete:async:isearch-update
	add-zle-hook-widget isearch-exit .autocomplete:async:isearch-exit
}
.autocomplete:async:pty () {
	if [[ -v DEBUG ]]
	then
		functions -T .autocomplete:async:pty:zle-widget
		set -x -o localoptions
		PS4=$_autocomplete__ps4 
	fi
	local -F seconds= 
	builtin zstyle -s :autocomplete: timeout seconds || seconds=0.5 
	TMOUT=$(( [#10] 1 + seconds )) 
	builtin bindkey $'\C-@' .autocomplete:async:pty:zle-widget
	local __tmp__= 
	builtin vared __tmp__
} 2>>| $_autocomplete__log
.autocomplete:async:pty:completion-widget () {
	{
		if ! .autocomplete:async:sufficient-input
		then
			return
		fi
		{
			unset 'compstate[vared]'
			.autocomplete:async:list-choices:main-complete
		} always {
			_autocomplete__list_lines=$compstate[list_lines] 
		}
	} 2>>| $_autocomplete__log
}
.autocomplete:async:pty:no-op () {
	:
}
.autocomplete:async:pty:zle-widget () {
	local -a _autocomplete__comp_mesg=() 
	local -i _autocomplete__list_lines=0 
	local _autocomplete__mesg= 
	{
		print -n -- '\C-A'
		LBUFFER=$_autocomplete__lbuffer 
		RBUFFER=$_autocomplete__rbuffer 
		setopt $_autocomplete__comp_opts[@]
		[[ -n $curcontext ]] && setopt $_autocomplete__ctxt_opts[@]
		[[ -v DEBUG ]] && functions -T .autocomplete:async:pty:completion-widget
		builtin zle .autocomplete:async:pty:completion-widget -w 2>>| $_autocomplete__log
	} always {
		print -rNC1 -- ${_autocomplete__list_lines:-0}$'\C-B'
		builtin exit
	}
} 2>>| $_autocomplete__log
.autocomplete:async:reset-context () {
	.autocomplete:async:reset-state
	typeset -g curcontext= 
	builtin zstyle -s :autocomplete: default-context curcontext
	.autocomplete:async:complete
	return 0
}
.autocomplete:async:reset-state () {
	unset _autocomplete__curcontext _autocomplete__lbuffer _autocomplete__rbuffer
}
.autocomplete:async:same-state () {
	[[ -v _autocomplete__curcontext && $_autocomplete__curcontext == $context && -v _autocomplete__lbuffer && $_autocomplete__lbuffer == $LBUFFER && -v _autocomplete__rbuffer && $_autocomplete__rbuffer == $RBUFFER ]]
}
.autocomplete:async:save-state () {
	typeset -g _autocomplete__curcontext=$context _autocomplete__lbuffer="$LBUFFER" _autocomplete__rbuffer="$RBUFFER" 
}
.autocomplete:async:start () {
	.autocomplete:async:save-state
	local fd= 
	sysopen -r -o cloexec -u fd <(
    .autocomplete:async:start:inner 2>>| $_autocomplete__log
  )
	builtin zle -Fw "$fd" .autocomplete:async:complete:fd-widget
	command true
}
.autocomplete:async:start:inner () {
	{
		if [[ -v DEBUG ]]
		then
			set -x
			PS4=$_autocomplete__ps4 
		fi
		typeset -F SECONDS=0 
		local -P hooks=(chpwd periodic precmd preexec zshaddhistory zshexit) 
		builtin unset ${^hooks}_functions &> /dev/null
		$hooks[@] () {
			:
		}
		local -P hook= 
		for hook in zle-{isearch-{exit,update},line-{pre-redraw,init,finish},history-line-set,keymap-select}
		do
			builtin zle -N $hook .autocomplete:async:pty:no-op
		done
		{
			local REPLY= 
			zpty AUTOCOMPLETE .autocomplete:async:pty
			local -Pi fd=$REPLY 
			zpty -w AUTOCOMPLETE $'\C-@'
			local header= 
			zpty -r AUTOCOMPLETE header $'*\C-A'
			local -a reply=() 
			local text= 
			builtin zstyle -s :autocomplete: timeout seconds || (( seconds = 0.4 ))
			local -i timeout=$(( 100 * max( 0, seconds - SECONDS ) )) 
			if zselect -rt $timeout "$fd"
			then
				zpty -r AUTOCOMPLETE text $'*\C-B'
			else
				zpty -wn AUTOCOMPLETE $'\C-C\C-C\C-D'
			fi
		} always {
			zpty -d AUTOCOMPLETE
		}
	} always {
		print -rNC1 -- "${text%$'\C-B'}"
	}
}
.autocomplete:async:sufficient-input () {
	local min_input= 
	if ! builtin zstyle -s ":autocomplete:${curcontext}:" min-input min_input
	then
		if [[ $curcontext == *history-* ]]
		then
			min_input=0 
		else
			min_input=1 
		fi
	fi
	local ignored= 
	builtin zstyle -s ":autocomplete:${curcontext}:" ignored-input ignored
	if (( ${#words[@]} == 1 && ${#words[CURRENT]} < min_input )) || [[ -n $ignored && $words[CURRENT] == $~ignored ]]
	then
		compstate[list]= 
		false
	else
		true
	fi
}
.autocomplete:async:wait () {
	local fd= 
	.autocomplete:async:save-state
	sysopen -r -o cloexec -u fd <(
    local -F seconds=
    builtin zstyle -s :autocomplete: delay seconds ||
        builtin zstyle -s :autocomplete: min-delay seconds ||
        (( seconds = 0.04 ))

    # WORKAROUND: #441 Directly using $(( [#10] … max( … ) )) leads to 0 in Zsh 5.9, as the result
    # of max() gets converted to an integer _before_ being multiplied.
    local -i timeout=$(( 100 * max( 0, seconds ) ))
    zselect -t $timeout

    print
  )
	builtin zle -Fw "$fd" .autocomplete:async:wait:fd-widget
	return 0
}
.autocomplete:async:wait:fd-widget () {
	{
		local -i fd=$1 
		builtin zle -F $fd
		exec {fd}<&-
		.autocomplete:zle-flags
		{
			if [[ -v DEBUG ]]
			then
				set -x -o localoptions
				local +h PS4=$_autocomplete__ps4 
			fi
			if .autocomplete:async:same-state
			then
				.autocomplete:async:start
			else
				.autocomplete:async:wait
			fi
			set +x
		} 2>>| $_autocomplete__log
	}
	return 0
}
.autocomplete:compinit:precmd () {
	emulate -L zsh
	setopt $_autocomplete__func_opts[@]
	[[ -v CDPATH && -z $CDPATH ]] && unset CDPATH cdpath
	local -Pa omzdump=() 
	[[ -v ZSH_COMPDUMP && -r $ZSH_COMPDUMP ]] && omzdump=(${(f)"$( < $ZSH_COMPDUMP )"}) 
	typeset -g _comp_dumpfile=${_comp_dumpfile:-${ZSH_COMPDUMP:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump}} 
	if [[ -v _comps[-command-] && $_comps[-command-] != _autocomplete__command ]]
	then
		zf_rm -f $_comp_dumpfile
	else
		local -Pa newest=(~autocomplete/Completions/_*~*.zwc(N-.omY1)) 
		if [[ $newest[1] -nt $_comp_dumpfile ]]
		then
			zf_rm -f $_comp_dumpfile
			break
		fi
	fi
	if [[ ! -v _comp_setup ]] || [[ ! -r $_comp_dumpfile ]]
	then
		unfunction compdef compinit 2> /dev/null
		bindkey () {
			:
		}
		{
			builtin autoload +X -Uz compinit
			local -a compargs=() 
			zstyle -a ':autocomplete::compinit' arguments compargs
			compinit -d "$_comp_dumpfile" "$compargs[@]"
		} always {
			unfunction bindkey
		}
		bindkey '^Xh' _complete_help
		(( ${#omzdump[@]} > 0 )) && tee -a "$ZSH_COMPDUMP" &> /dev/null <<EOF
$omzdump[-2]
$omzdump[-1]
EOF
	fi
	compinit () {
		:
	}
	local -P args= 
	for args in "$_autocomplete__compdef[@]"
	do
		eval "compdef $args"
	done
	unset _autocomplete__compdef
	(
		local -a reply=() 
		local cache_dir= 
		if builtin zstyle -s ':completion:*' cache-path cache_dir
		then
			local -P src= bin= 
			for src in $cache_dir/*~**.zwc~**/.*(N-.)
			do
				bin=$src.zwc 
				if [[ ! -e $bin || $bin -ot $src ]]
				then
					zcompile -Uz $src
				fi
			done
		fi
	) &|
	.autocomplete:patch _main_complete
	autocomplete:_main_complete:new () {
		local -i _autocomplete__reserved_lines=0 
		local -Pi ret=1 
		unset _autocomplete__partial_list _autocomplete__unambiguous
		compstate[insert]=menu 
		compstate[last_prompt]=yes 
		compstate[list]='list force packed rows' 
		unset 'compstate[vared]'
		local +h -a comppostfuncs=(autocomplete:_main_complete:new:post "$comppostfuncs[@]") 
		autocomplete:_main_complete:old "$@"
	}
	autocomplete:_main_complete:new:post () {
		[[ $WIDGET != _complete_help ]] && unfunction compadd 2> /dev/null
		_autocomplete__unambiguous
		compstate[list_max]=0 
		MENUSCROLL=0 
	}
	.autocomplete:patch _expand
	_expand () {
		if _autocomplete__is_glob
		then
			compstate[pattern_insert]= 
			compstate[pattern_match]=\* 
			autocomplete:_expand:old "$@"
			return
		fi
		autocomplete:_expand:old "$@"
	}
	.autocomplete:patch _complete
	_complete () {
		local -i nmatches=$compstate[nmatches] 
		PREFIX=$PREFIX$SUFFIX 
		SUFFIX= 
		autocomplete:_complete:old "$@" || _autocomplete__ancestor_dirs "$@" || _autocomplete__recent_paths "$@"
		(( compstate[nmatches] > nmatches ))
	}
	.autocomplete:patch _approximate
	_approximate () {
		{
			[[ -v functions[compadd] ]] && functions[autocomplete:compadd:old]="$functions[compadd]" 
			functions[compadd]="$functions[autocomplete:approximate:compadd]" 
			autocomplete:_approximate:old
		} always {
			unfunction compadd 2> /dev/null
			if [[ -v functions[autocomplete:compadd:old] ]]
			then
				functions[compadd]="$functions[autocomplete:compadd:old]" 
				unfunction autocomplete:compadd:old
			fi
		}
	}
	autocomplete:approximate:compadd () {
		local ppre="$argv[(I)-p]" 
		[[ ${argv[(I)-[a-zA-Z]#U[a-zA-Z]#]} -eq 0 && "${#:-$PREFIX$SUFFIX}" -le _comp_correct ]] && return
		if [[ "$PREFIX" = \~* && ( ppre -eq 0 || "$argv[ppre+1]" != \~* ) ]]
		then
			PREFIX="~(#a${_comp_correct})${PREFIX[2,-1]}" 
		else
			PREFIX="(#a${_comp_correct})$PREFIX" 
		fi
		if [[ -v functions[autocomplete:compadd:old] ]]
		then
			autocomplete:compadd:old "$@"
		else
			builtin compadd "$@"
		fi
	}
}
.autocomplete:complete-word:completion-widget () {
	zmodload -F zsh/terminfo p:terminfo
	local +h curcontext=${curcontext:-${WIDGET}:::} 
	local +h -a comppostfuncs=(.autocomplete:complete-word:post "$comppostfuncs[@]") 
	if [[ -z $compstate[old_list] && $curcontext == history-incremental-search* ]]
	then
		autocomplete:_main_complete:new - history-lines _autocomplete__history_lines
	elif [[ -z $compstate[old_list] ]] || [[ -v _autocomplete__partial_list && $WIDGETSTYLE == (|*-)(list|menu)(|-*) ]] || _autocomplete__should_insert_unambiguous
	then
		compstate[old_list]= 
		autocomplete:_main_complete:new
	else
		compstate[old_list]=keep 
		autocomplete:_main_complete:new -
	fi
	unset curcontext
	[[ $_lastcomp[nmatches] -gt 0 && -n $compstate[insert] ]]
}
.autocomplete:complete-word:post () {
	local -a match=() mbegin=() mend=() 
	unset MENUMODE MENUSELECT
	if [[ $_completer == _prefix ]]
	then
		compstate[to_end]= 
	else
		compstate[to_end]='always' 
	fi
	if _autocomplete__should_insert_unambiguous
	then
		if [[ $WIDGETSTYLE == (|*-)menu(|-*) ]]
		then
			compstate[insert]='automenu-' 
		else
			compstate[insert]= 
		fi
		compstate[insert]+='unambiguous' 
		compstate[list]='list force' 
		unset _autocomplete__unambiguous
	else
		if [[ $WIDGETSTYLE == (|*-)menu(|-*) ]]
		then
			if [[ $WIDGETSTYLE == (|*-)select(|-*) ]]
			then
				typeset -gi MENUSELECT=0 
				if [[ $WIDGET == (|*-)search(|-*) ]]
				then
					typeset -g MENUMODE=search-forward 
				fi
			fi
			compstate[insert]='menu:' 
			compstate[list]='list force' 
		else
			compstate[insert]= 
			compstate[list]= 
			zle -Rc
		fi
		if [[ $WIDGET == (|.)reverse-* || $WIDGETSTYLE == (|.)reverse-menu-complete ]]
		then
			compstate[insert]+='0' 
		else
			compstate[insert]+='1' 
		fi
		local -Pa comptags=() 
		if [[ $compstate[old_list] == keep ]]
		then
			comptags=($=_lastcomp[tags]) 
		else
			comptags=($=_comp_tags) 
		fi
		local -a spacetags=() 
		builtin zstyle -a :autocomplete: add-space spacetags || spacetags=(executables aliases functions builtins reserved-words commands) 
		[[ -n ${comptags:*spacetags} ]] && compstate[insert]+=' ' 
	fi
}
.autocomplete:config:precmd () {
	typeset -g _comp_setup="$_comp_setup"';
      [[ $_comp_caller_options[globdots] == yes ]] && setopt globdots' 
	local -P key= setting= 
	for key in menu list-prompt
	do
		for setting in ${(f)"$( zstyle -L '*' $key )"}
		do
			eval "${setting/zstyle(| -e)/zstyle -d}"
		done
	done
	builtin zstyle ':completion:*:*:*:*:default' menu no no-select
	unset LISTPROMPT
}
.autocomplete:down-line-or-select:zle-widget () {
	if [[ $RBUFFER == *$'\n'* ]]
	then
		builtin zle down-line
	else
		builtin zle menu-select -w
	fi
}
.autocomplete:history-search:completion-widget () {
	local 0=${(%):-%N} 
	${0} () {
		typeset -g curcontext=${WIDGET}::: 
		local +h -a comppostfuncs=(${(%):-%N}:post "$comppostfuncs[@]") 
		compstate[old_list]= 
		autocomplete:_main_complete:new - history-lines _autocomplete__history_lines
		unset curcontext
		(( _lastcomp[nmatches] ))
	}
	${0}:post () {
		typeset -gi MENUSELECT=0 
		compstate[insert]='menu:0' 
	}
	${0} "$@"
}
.autocomplete:key-bindings:bind () {
	local -P keymap=$1 widget=$2 
	shift 2
	builtin bindkey -M "$keymap" "${@:^^widget}"
}
.autocomplete:key-bindings:bind-menu () {
	0=${0%:*} 
	${0}:bind isearch "$@"
	${0}:bind menuselect "$@"
}
.autocomplete:key-bindings:bound () {
	[[ $( builtin bindkey -M "$1" "$3" ) == \"[^[:space:]]##\"\ $2 ]]
}
.autocomplete:key-bindings:precmd () {
	emulate -L zsh
	setopt $_autocomplete__func_opts[@]
	0=${0%:*} 
	${0}:rebind main expand-or-complete complete-word '\t'
	${0}:rebind main expand-or-complete-prefix complete-word '\t'
	${0}:rebind main menu-expand-or-complete complete-word '\t'
	local backtab=$terminfo[kcbt] 
	${0}:rebind main undefined-key insert-unambiguous-or-complete "$backtab"
	${0}:bound main complete-word '\t' && ${0}:bind-menu accept-line '\t'
	${0}:bind main history-search-backward $_autocomplete__key_alt_up[@]
	${0}:bind-menu vi-backward-blank-word $_autocomplete__key_alt_up[@]
	${0}:bind main menu-select $_autocomplete__key_alt_down[@]
	${0}:bind-menu vi-forward-blank-word $_autocomplete__key_alt_down[@]
	${0}:rebind emacs history-search-backward history-search-backward '\ep'
	${0}:bind-menu vi-backward-blank-word '\ep'
	${0}:rebind emacs history-search-forward menu-select '\en'
	${0}:bind-menu vi-forward-blank-word '\en'
	${0}:rebind vicmd vi-rev-repeat-search history-search-backward 'N'
	${0}:rebind vicmd vi-repeat-search menu-select 'n'
	${0}:rebind emacs history-incremental-search-backward{,} '^R'
	${0}:bind-menu history-incremental-search-backward '^R'
	${0}:rebind emacs history-incremental-search-forward menu-search '^S'
	${0}:bind-menu history-incremental-search-forward '^S'
	${0}:rebind vicmd {vi-history,history-incremental}-search-backward '/'
	${0}:rebind vicmd vi-history-search-forward menu-search '?'
	unset -m '_autocomplete__key_*'
	unfunction ${0}:{{,re,un}bind,bound}
}
.autocomplete:key-bindings:rebind () {
	0=${0%:*} 
	local -P keymap=$1 old=$2 new=$3 key= 
	shift 3
	for key
	do
		${0}:bound "$keymap" "$old" "$key" && builtin bindkey -M "$keymap" "$key" "$new"
	done
}
.autocomplete:key-bindings:unbind () {
	0=${0%:*} 
	${0}:bound "$1" "$2" "$3" && builtin bindkey -M "$1" -r "$2"
}
.autocomplete:patch () {
	zmodload -F zsh/parameter p:functions
	functions[autocomplete:${1}:old]="$(
    unfunction $1 2> /dev/null
    builtin autoload +X -Uz $1
    print -r -- "$functions[$1]"
)" 
}
.autocomplete:recent-dirs:precmd () {
	if [[ ! -v functions[+autocomplete:recent-directories] ]]
	then
		setopt autopushd pushdignoredups
		builtin autoload -RUz chpwd_recent_filehandler
		local __='' 
		builtin zstyle -s :chpwd: recent-dirs-file __ || builtin zstyle ':chpwd:*' recent-dirs-file ${XDG_DATA_HOME:-$HOME/.local/share}/zsh/chpwd-recent-dirs
		builtin zstyle -s :chpwd: recent-dirs-max __ || builtin zstyle ':chpwd:*' recent-dirs-max 0
		if ! (( $#dirstack[@] ))
		then
			local -aU reply=() 
			chpwd_recent_filehandler
			dirstack=(${^reply[@]:#$PWD}(N-/)) 
		fi
		+autocomplete:recent-directories:save () {
			chpwd_recent_filehandler $PWD $dirstack[@]
		}
		add-zsh-hook chpwd +autocomplete:recent-directories:save
		+autocomplete:recent-directories () {
			reply=(${^dirstack[@]:#$PWD(|/[^/]#)}(N)) 
			local -P ancestor=$PWD:h 
			while [[ $ancestor != / ]]
			do
				reply=(${reply[@]:#$ancestor}) 
				ancestor=$ancestor:h 
			done
			local exact=$reply[(r)*/$PREFIX$SUFFIX] 
			[[ -n $exact ]] && reply=($exact ${reply[@]:#$exact}) 
			(( $#reply[@] ))
		}
	fi
}
.autocomplete:up-line-or-search:zle-widget () {
	if [[ $LBUFFER == *$'\n'* ]]
	then
		builtin zle up-line
	else
		builtin zle history-search-backward -w
	fi
}
.autocomplete:widgets:c () {
	_autocomplete__suggest_ignore_widgets+=($1) 
	builtin zle -C "$1" "$2" .autocomplete:${3}:completion-widget
}
.autocomplete:widgets:precmd () {
	emulate -L zsh
	setopt $_autocomplete__func_opts[@]
	0=${0%:*} 
	local -P tab_style= 
	for tab_style in complete-word menu-complete menu-select
	do
		${0}:c "$tab_style" "$tab_style" complete-word
	done
	${0}:c {,}reverse-menu-complete complete-word
	${0}:c insert-unambiguous-or-complete {,}complete-word
	${0}:c menu-search menu-select complete-word
	${0}:c history-search-backward menu-select history-search
	[[ -v ZSH_AUTOSUGGEST_IGNORE_WIDGETS ]] && ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=($_autocomplete__suggest_ignore_widgets) 
	unset _autocomplete__suggest_ignore_widgets
	unfunction ${0}:{c,z}
}
.autocomplete:widgets:z () {
	builtin zle -N "$1" .autocomplete:${2}:zle-widget
}
.autocomplete:zle-flags () {
	typeset -g _autocomplete__last_widget= 
	.autocomplete:zle-flags () {
		emulate -L zsh
		setopt $_autocomplete__func_opts[@]
		[[ -v 1 && -n $1 ]] && typeset -g _autocomplete__last_widget="$1" 
		case $_autocomplete__last_widget in
			(*kill-*~vi-*) builtin zle -f kill
				return 0 ;;
			(bracketed-paste) builtin zle -f yank
				return 0 ;;
			(*yank*~vi-*|vi-*put-*after) builtin zle -f yank
				return 1 ;;
			(vi-*put-*before) builtin zle -f yankbefore
				return 1 ;;
			(*) return 0 ;;
		esac
	}
	.autocomplete:zle-flags "$@"
}
add-zle-hook-widget () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi
}
asdf () {
	case $1 in
		("shell") if ! shift
			then
				printf '%s\n' 'asdf: Error: Failed to shift' >&2
				return 1
			fi
			eval "$(asdf export-shell-version sh "$@")" ;;
		(*) command asdf "$@" ;;
	esac
}
autocomplete:config:cache-path () {
	reply=("${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache") 
}
autocomplete:config:file-patterns:command () {
	[[ $PREFIX$SUFFIX != */* ]] && reply=('*(-/):directories:directory ./*(-*^/):executables:"executable file"') 
}
autocomplete:config:format:warnings () {
	[[ $CURRENT == 1 && -z $PREFIX$SUFFIX ]] || reply=($'%{\e[0;2m%}'"no matching %d completions"$'%{\e[0m%}') 
}
autocomplete:config:substitute:expand () {
	local -P __word__=$PREFIX$SUFFIX 
	if [[ ${(Q)__word__} == *(\`*\`|\$\(*\))* ]]
	then
		reply=(false) 
	else
		reply=(true) 
	fi
}
autocomplete:config:tag-order:command () {
	if [[ $PREFIX == (|.|*/*) ]]
	then
		reply=('suffix-aliases (|*-)directories executables (|*-)files' -) 
	else
		reply=(aliases suffix-aliases functions 'reserved-words builtins') 
		if [[ -n $path[(r).] ]]
		then
			reply+=('(|*-)directories executables (|*-)files' commands) 
		else
			reply+=(commands '(|*-)directories executables (|*-)files') 
		fi
	fi
}
chpwd_update_git_vars () {
	update_current_git_vars
}
colors () {
	emulate -L zsh
	typeset -Ag color colour
	color=(00 none 01 bold 02 faint 22 normal 03 italic 23 no-italic 04 underline 24 no-underline 05 blink 25 no-blink 07 reverse 27 no-reverse 08 conceal 28 no-conceal 30 black 40 bg-black 31 red 41 bg-red 32 green 42 bg-green 33 yellow 43 bg-yellow 34 blue 44 bg-blue 35 magenta 45 bg-magenta 36 cyan 46 bg-cyan 37 white 47 bg-white 39 default 49 bg-default) 
	local k
	for k in ${(k)color}
	do
		color[${color[$k]}]=$k 
	done
	for k in ${color[(I)3?]}
	do
		color[fg-${color[$k]}]=$k 
	done
	for k in grey gray
	do
		color[$k]=${color[black]} 
		color[fg-$k]=${color[$k]} 
		color[bg-$k]=${color[bg-black]} 
	done
	colour=(${(kv)color}) 
	local lc=$'\e[' rc=m 
	typeset -Hg reset_color bold_color
	reset_color="$lc${color[none]}$rc" 
	bold_color="$lc${color[bold]}$rc" 
	typeset -AHg fg fg_bold fg_no_bold
	for k in ${(k)color[(I)fg-*]}
	do
		fg[${k#fg-}]="$lc${color[$k]}$rc" 
		fg_bold[${k#fg-}]="$lc${color[bold]};${color[$k]}$rc" 
		fg_no_bold[${k#fg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
	typeset -AHg bg bg_bold bg_no_bold
	for k in ${(k)color[(I)bg-*]}
	do
		bg[${k#bg-}]="$lc${color[$k]}$rc" 
		bg_bold[${k#bg-}]="$lc${color[bold]};${color[$k]}$rc" 
		bg_no_bold[${k#bg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
}
compdef () {
	typeset -ga _autocomplete__compdef=($_autocomplete__compdef[@] "${(j: :)${(@q+)@}}") 
}
compgen () {
	unfunction _bash_complete compgen complete
	builtin autoload +X -Uz bashcompinit
	bashcompinit
	bashcompinit () {
		:
	}
	${(%):-%N} "$@"
}
complete () {
	unfunction _bash_complete compgen complete
	builtin autoload +X -Uz bashcompinit
	bashcompinit
	bashcompinit () {
		:
	}
	${(%):-%N} "$@"
}
ensure_tmux_is_running () {
	if _not_inside_tmux
	then
		tat
	fi
}
git_super_status () {
	precmd_update_git_vars
	if [ -n "$__CURRENT_GIT_STATUS" ]
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_PREFIX$ZSH_THEME_GIT_PROMPT_BRANCH$GIT_BRANCH%{${reset_color}%}" 
		if [ "$GIT_BEHIND" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_BEHIND$GIT_BEHIND%{${reset_color}%}" 
		fi
		if [ "$GIT_AHEAD" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_AHEAD$GIT_AHEAD%{${reset_color}%}" 
		fi
		STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_SEPARATOR" 
		if [ "$GIT_STAGED" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_STAGED$GIT_STAGED%{${reset_color}%}" 
		fi
		if [ "$GIT_CONFLICTS" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CONFLICTS$GIT_CONFLICTS%{${reset_color}%}" 
		fi
		if [ "$GIT_CHANGED" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CHANGED$GIT_CHANGED%{${reset_color}%}" 
		fi
		if [ "$GIT_UNTRACKED" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED%{${reset_color}%}" 
		fi
		if [ "$GIT_CHANGED" -eq "0" ] && [ "$GIT_CONFLICTS" -eq "0" ] && [ "$GIT_STAGED" -eq "0" ] && [ "$GIT_UNTRACKED" -eq "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CLEAN" 
		fi
		STATUS="$STATUS%{${reset_color}%}$ZSH_THEME_GIT_PROMPT_SUFFIX" 
		echo "$STATUS"
	fi
}
is-at-least () {
	emulate -L zsh
	local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version order 
	min_ver=(${=1}) 
	version=(${=2:-$ZSH_VERSION} 0) 
	while (( $min_cnt <= ${#min_ver} ))
	do
		while [[ "$part" != <-> ]]
		do
			(( ++ver_cnt > ${#version} )) && return 0
			if [[ ${version[ver_cnt]} = *[0-9][^0-9]* ]]
			then
				order=(${version[ver_cnt]} ${min_ver[ver_cnt]}) 
				if [[ ${version[ver_cnt]} = <->* ]]
				then
					[[ $order != ${${(On)order}} ]] && return 1
				else
					[[ $order != ${${(O)order}} ]] && return 1
				fi
				[[ $order[1] != $order[2] ]] && return 0
			fi
			part=${version[ver_cnt]##*[^0-9]} 
		done
		while true
		do
			(( ++min_cnt > ${#min_ver} )) && return 0
			[[ ${min_ver[min_cnt]} = <-> ]] && break
		done
		(( part > min_ver[min_cnt] )) && return 0
		(( part < min_ver[min_cnt] )) && return 1
		part='' 
	done
}
precmd_update_git_vars () {
	if [ -n "$__EXECUTED_GIT_COMMAND" ] || [ ! -n "$ZSH_THEME_GIT_PROMPT_CACHE" ]
	then
		update_current_git_vars
		unset __EXECUTED_GIT_COMMAND
	fi
}
preexec_update_git_vars () {
	case "$2" in
		(git* | hub* | gh* | stg*) __EXECUTED_GIT_COMMAND=1  ;;
	esac
}
rg_vim () {
	rg -l "$1" | xargs -o nvim
}
update_current_git_vars () {
	unset __CURRENT_GIT_STATUS
	if [[ "$GIT_PROMPT_EXECUTABLE" == "python" ]]
	then
		local gitstatus="$__GIT_PROMPT_DIR/gitstatus.py" 
		_GIT_STATUS=`python ${gitstatus} 2>/dev/null` 
	fi
	if [[ "$GIT_PROMPT_EXECUTABLE" == "haskell" ]]
	then
		_GIT_STATUS=`git status --porcelain --branch &> /dev/null | $__GIT_PROMPT_DIR/src/.bin/gitstatus` 
	fi
	__CURRENT_GIT_STATUS=("${(@s: :)_GIT_STATUS}") 
	GIT_BRANCH=$__CURRENT_GIT_STATUS[1] 
	GIT_AHEAD=$__CURRENT_GIT_STATUS[2] 
	GIT_BEHIND=$__CURRENT_GIT_STATUS[3] 
	GIT_STAGED=$__CURRENT_GIT_STATUS[4] 
	GIT_CONFLICTS=$__CURRENT_GIT_STATUS[5] 
	GIT_CHANGED=$__CURRENT_GIT_STATUS[6] 
	GIT_UNTRACKED=$__CURRENT_GIT_STATUS[7] 
}
zmathfunc () {
	zsh_math_func_min () {
		emulate -L zsh
		local result=$1 
		shift
		local arg
		for arg
		do
			(( arg < result ))
			case $? in
				(0) (( result = arg )) ;;
				(1)  ;;
				(*) return $? ;;
			esac
		done
		(( result ))
		true
	}
	functions -M min 1 -1 zsh_math_func_min
	zsh_math_func_max () {
		emulate -L zsh
		local result=$1 
		shift
		local arg
		for arg
		do
			(( arg > result ))
			case $? in
				(0) (( result = arg )) ;;
				(1)  ;;
				(*) return $? ;;
			esac
		done
		(( result ))
		true
	}
	functions -M max 1 -1 zsh_math_func_max
	zsh_math_func_sum () {
		emulate -L zsh
		local sum
		local arg
		for arg
		do
			(( sum += arg ))
		done
		(( sum ))
		true
	}
	functions -M sum 0 -1 zsh_math_func_sum
}
zsh_math_func_max () {
	emulate -L zsh
	local result=$1 
	shift
	local arg
	for arg
	do
		(( arg > result ))
		case $? in
			(0) (( result = arg )) ;;
			(1)  ;;
			(*) return $? ;;
		esac
	done
	(( result ))
	true
}
zsh_math_func_min () {
	emulate -L zsh
	local result=$1 
	shift
	local arg
	for arg
	do
		(( arg < result ))
		case $? in
			(0) (( result = arg )) ;;
			(1)  ;;
			(*) return $? ;;
		esac
	done
	(( result ))
	true
}
zsh_math_func_sum () {
	emulate -L zsh
	local sum
	local arg
	for arg
	do
		(( sum += arg ))
	done
	(( sum ))
	true
}
zvm_append_eol () {
	ZVM_INSERT_MODE='A' 
	zle vi-end-of-line
	CURSOR=$((CURSOR+1)) 
	zvm_select_vi_mode $ZVM_MODE_INSERT
	zvm_reset_repeat_commands $ZVM_MODE_NORMAL $ZVM_INSERT_MODE
}
zvm_backward_kill_line () {
	BUFFER=${BUFFER:$CURSOR:$#BUFFER} 
	CURSOR=0 
}
zvm_backward_kill_region () {
	local bpos=$CURSOR-1 epos=$CURSOR 
	for ((; bpos >= 0; bpos--)) do
		[[ "${BUFFER:$bpos:1}" == $'\n' ]] && break
		[[ "${BUFFER:$bpos:2}" =~ ^\ [^\ $'\n']$ ]] && break
	done
	bpos=$bpos+1 
	CUTBUFFER=${BUFFER:$bpos:$((epos-bpos))} 
	BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}" 
	CURSOR=$bpos 
}
zvm_bindkey () {
	local keymap=$1 
	local keys=$2 
	local widget=$3 
	local params=$4 
	local key= 
	[[ -z $widget ]] && return
	if [[ -n ${ZVM_LAZY_KEYBINDINGS_LIST+x} && ${keymap} != viins ]]
	then
		keys=${keys//\"/\\\"} 
		keys=${keys//\`/\\\`} 
		ZVM_LAZY_KEYBINDINGS_LIST+=("${keymap} \"${keys}\" ${widget} \"${params}\"") 
		return
	fi
	if [[ $ZVM_READKEY_ENGINE == $ZVM_READKEY_ENGINE_NEX ]]
	then
		if [[ $#keys -gt 1 && "${keys:0:1}" == '^' ]]
		then
			key=${keys:0:2} 
		else
			key=${keys:0:1} 
		fi
		bindkey -M $keymap "${key}" zvm_readkeys_handler
	fi
	if [[ -n $params ]]
	then
		local suffix=$(zvm_string_to_hex $params) 
		eval "$widget:$suffix() { $widget $params }"
		widget="$widget:$suffix" 
		zvm_define_widget $widget
	fi
	bindkey -M $keymap "${keys}" $widget
}
zvm_calc_selection () {
	local ret=($(zvm_selection)) 
	local bpos=${ret[1]} epos=${ret[2]} cpos= 
	cpos=$bpos 
	if [[ "${1:-$ZVM_MODE}" == $ZVM_MODE_VISUAL_LINE ]]
	then
		for ((bpos=$bpos-1; $bpos>0; bpos--)) do
			if [[ "${BUFFER:$bpos:1}" == $'\n' ]]
			then
				bpos=$((bpos+1)) 
				break
			fi
		done
		for ((epos=$epos-1; $epos<$#BUFFER; epos++)) do
			if [[ "${BUFFER:$epos:1}" == $'\n' ]]
			then
				break
			fi
		done
		if (( bpos < 0 ))
		then
			bpos=0 
		fi
		for ((cpos=$((CURSOR-1)); $cpos>=0; cpos--)) do
			[[ "${BUFFER:$cpos:1}" == $'\n' ]] && break
		done
		local indent=$((CURSOR-cpos-1)) 
		local hpos= 
		local rpos= 
		if (( $epos < $#BUFFER ))
		then
			hpos=$((epos+1)) 
			rpos=$bpos 
		else
			for ((hpos=$((bpos-2)); $hpos>0; hpos--)) do
				if [[ "${BUFFER:$hpos:1}" == $'\n' ]]
				then
					break
				fi
			done
			if (( $hpos < -1 ))
			then
				hpos=-1 
			fi
			hpos=$((hpos+1)) 
			rpos=$hpos 
		fi
		for ((cpos=$hpos; $cpos<$#BUFFER; cpos++)) do
			if [[ "${BUFFER:$cpos:1}" == $'\n' ]]
			then
				break
			fi
			if (( $hpos + $indent <= $cpos ))
			then
				break
			fi
		done
		cpos=$((rpos+cpos-hpos)) 
	fi
	echo $bpos $epos $cpos
}
zvm_change_surround () {
	local ret=($(zvm_parse_surround_keys)) 
	local action=${1:-${ret[1]}} 
	local surround=${2:-${ret[2]//$ZVM_ESCAPE_SPACE/ }} 
	local bpos=${3} epos=${4} 
	local is_appending=false 
	case $action in
		(S | y | a) is_appending=true  ;;
	esac
	if $is_appending
	then
		if [[ -z $bpos && -z $epos ]]
		then
			ret=($(zvm_selection)) 
			bpos=${ret[1]} epos=${ret[2]} 
		fi
	else
		ret=($(zvm_search_surround "$surround")) 
		(( ${#ret[@]} )) || return
		bpos=${ret[1]} epos=${ret[2]} 
		zvm_highlight custom $bpos $(($bpos+1))
		zvm_highlight custom $epos $(($epos+1))
	fi
	local key= 
	case $action in
		(c | r) zvm_enter_oppend_mode
			read -k 1 key
			zvm_exit_oppend_mode ;;
		(S | y | a) if [[ -z $surround ]]
			then
				zvm_enter_oppend_mode
				read -k 1 key
				zvm_exit_oppend_mode
			else
				key=$surround 
			fi
			if [[ $ZVM_MODE == $ZVM_MODE_VISUAL ]]
			then
				zle visual-mode
			fi ;;
	esac
	case "$key" in
		($'\e' | "${ZVM_VI_ESCAPE_BINDKEY//\^\[/$'\e'}") zvm_highlight clear
			return ;;
	esac
	ret=($(zvm_match_surround "$key")) 
	local bchar=${${ret[1]//$ZVM_ESCAPE_SPACE/ }:-$key} 
	local echar=${${ret[2]//$ZVM_ESCAPE_SPACE/ }:-$key} 
	local value=$($is_appending && echo 0 || echo 1 ) 
	local head=${BUFFER:0:$bpos} 
	local body=${BUFFER:$((bpos+value)):$((epos-(bpos+value)))} 
	local foot=${BUFFER:$((epos+value))} 
	BUFFER="${head}${bchar}${body}${echar}${foot}" 
	zvm_highlight clear
	case $action in
		(S | y | a) zvm_select_vi_mode $ZVM_MODE_NORMAL ;;
	esac
}
zvm_change_surround_text_object () {
	local ret=($(zvm_parse_surround_keys)) 
	local action=${ret[1]} 
	local surround=${ret[2]//$ZVM_ESCAPE_SPACE/ } 
	ret=($(zvm_search_surround "${surround}")) 
	if [[ ${#ret[@]} == 0 ]]
	then
		zvm_select_vi_mode $ZVM_MODE_NORMAL
		return
	fi
	local bpos=${ret[1]} 
	local epos=${ret[2]} 
	if [[ ${action:1:1} == 'i' ]]
	then
		((bpos++))
	else
		((epos++))
	fi
	CUTBUFFER=${BUFFER:$bpos:$(($epos-$bpos))} 
	case ${action:0:1} in
		(c) BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}" 
			CURSOR=$bpos 
			zvm_select_vi_mode $ZVM_MODE_INSERT ;;
		(d) BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}" 
			CURSOR=$bpos  ;;
	esac
}
zvm_cursor_style () {
	local style=${(L)1} 
	local term=${2:-$ZVM_TERM} 
	case $term in
		(xterm* | rxvt* | screen* | tmux* | konsole* | alacritty* | st*) case $style in
				($ZVM_CURSOR_BLOCK) style='\e[2 q'  ;;
				($ZVM_CURSOR_UNDERLINE) style='\e[4 q'  ;;
				($ZVM_CURSOR_BEAM) style='\e[6 q'  ;;
				($ZVM_CURSOR_BLINKING_BLOCK) style='\e[1 q'  ;;
				($ZVM_CURSOR_BLINKING_UNDERLINE) style='\e[3 q'  ;;
				($ZVM_CURSOR_BLINKING_BEAM) style='\e[5 q'  ;;
				($ZVM_CURSOR_USER_DEFAULT) style='\e[0 q'  ;;
			esac ;;
		(*) style='\e[0 q'  ;;
	esac
	if [[ $style == '\e[0 q' ]]
	then
		local old_style= 
		case $ZVM_MODE in
			($ZVM_MODE_INSERT) old_style=$ZVM_INSERT_MODE_CURSOR  ;;
			($ZVM_MODE_NORMAL) old_style=$ZVM_NORMAL_MODE_CURSOR  ;;
			($ZVM_MODE_OPPEND) old_style=$ZVM_OPPEND_MODE_CURSOR  ;;
		esac
		if [[ $old_style =~ '\e\][0-9]+;.+\a' ]]
		then
			style=$style'\e\e]112\a' 
		fi
	fi
	echo $style
}
zvm_default_handler () {
	local keys=$(zvm_keys) 
	local extra_keys=$1 
	case $(zvm_escape_non_printed_characters "$keys") in
		('^[' | $ZVM_VI_INSERT_ESCAPE_BINDKEY) zvm_exit_insert_mode false
			ZVM_KEYS=${extra_keys} 
			return ;;
		([vV]'^[' | [vV]$ZVM_VI_VISUAL_ESCAPE_BINDKEY) zvm_exit_visual_mode false
			ZVM_KEYS=${extra_keys} 
			return ;;
	esac
	case "$KEYMAP" in
		(vicmd) case "$keys" in
				([vV]c) zvm_vi_change false ;;
				([vV]d) zvm_vi_delete false ;;
				([vV]y) zvm_vi_yank false ;;
				([vV]S) zvm_change_surround S ;;
				([cdyvV]*) zvm_range_handler "${keys}${extra_keys}" ;;
				(*) for ((i=0; i<$#keys; i++)) do
						zvm_navigation_handler ${keys:$i:1}
						zvm_highlight
					done ;;
			esac ;;
		(viins | main) if [[ "${keys:0:1}" =~ [a-zA-Z0-9\ ] ]]
			then
				zvm_self_insert "${keys:0:1}"
				zle redisplay
				ZVM_KEYS="${keys:1}${extra_keys}" 
				return
			elif [[ "${keys:0:1}" == $'\e' ]]
			then
				zvm_exit_insert_mode false
				ZVM_KEYS="${keys:1}${extra_keys}" 
				return
			fi ;;
		(visual)  ;;
	esac
	ZVM_KEYS= 
}
zvm_define_widget () {
	local widget=$1 
	local func=$2  || $1
	local result=($(zle -l -L "${widget}")) 
	if [[ ${#result[@]} == 4 ]]
	then
		local rawfunc=${result[4]} 
		local wrapper="zvm_${widget}-wrapper" 
		eval "$wrapper() { zvm_widget_wrapper $rawfunc $func \"\$@\" }"
		func=$wrapper 
	fi
	zle -N $widget $func
}
zvm_enter_insert_mode () {
	local keys=${1:-$(zvm_keys)} 
	if [[ $keys == 'i' ]]
	then
		ZVM_INSERT_MODE='i' 
	elif [[ $keys == 'a' ]]
	then
		ZVM_INSERT_MODE='a' 
		if ! zvm_is_empty_line
		then
			CURSOR=$((CURSOR+1)) 
		fi
	fi
	zvm_reset_repeat_commands $ZVM_MODE_NORMAL $ZVM_INSERT_MODE
	zvm_select_vi_mode $ZVM_MODE_INSERT
}
zvm_enter_oppend_mode () {
	ZVM_OPPEND_MODE=true 
	${1:-true} && zvm_update_cursor
}
zvm_enter_visual_mode () {
	local mode= 
	local last_mode=$ZVM_MODE 
	local last_region= 
	case $last_mode in
		($ZVM_MODE_VISUAL | $ZVM_MODE_VISUAL_LINE) last_region=($MARK $CURSOR) 
			zvm_exit_visual_mode ;;
	esac
	case "${1:-$(zvm_keys)}" in
		(v) mode=$ZVM_MODE_VISUAL  ;;
		(V) mode=$ZVM_MODE_VISUAL_LINE  ;;
		(*) mode=$last_mode  ;;
	esac
	if [[ $last_mode == $mode ]]
	then
		return
	fi
	zvm_select_vi_mode $mode
	if [[ -n $last_region ]]
	then
		MARK=$last_region[1] 
		CURSOR=$last_region[2] 
		zle redisplay
	fi
}
zvm_escape_non_printed_characters () {
	local str= 
	for ((i=0; i<$#1; i++)) do
		local c=${1:$i:1} 
		if [[ "$c" < ' ' ]]
		then
			local ord=$(($(printf '%d' "'$c")+64)) 
			c=$(printf \\$(printf '%03o' $ord)) 
			str="${str}^${c}" 
		elif [[ "$c" == '' ]]
		then
			str="${str}^?" 
		elif [[ "$c" == ' ' ]]
		then
			str="${str}^@" 
		else
			str="${str}${c}" 
		fi
	done
	str=${str// /$ZVM_ESCAPE_SPACE} 
	str=${str//$'\n'/$ZVM_ESCAPE_NEWLINE} 
	echo -n $str
}
zvm_exchange_point_and_mark () {
	cursor=$MARK 
	MARK=$CURSOR CURSOR=$cursor 
	zvm_highlight
}
zvm_exec_commands () {
	local commands="zvm_${1}_commands" 
	commands=(${(P)commands}) 
	if zvm_exist_command "zvm_$1"
	then
		eval "zvm_$1" ${@:2}
	fi
	for cmd in $commands
	do
		if zvm_exist_command ${cmd}
		then
			cmd="$cmd ${@:2}" 
		fi
		eval $cmd
	done
}
zvm_exist_command () {
	command -v "$1" > /dev/null
}
zvm_exit_insert_mode () {
	ZVM_INSERT_MODE= 
	zvm_select_vi_mode $ZVM_MODE_NORMAL ${1:-true}
}
zvm_exit_oppend_mode () {
	ZVM_OPPEND_MODE=false 
	${1:-true} && zvm_update_cursor
}
zvm_exit_visual_mode () {
	case "$ZVM_MODE" in
		($ZVM_MODE_VISUAL) zle visual-mode ;;
		($ZVM_MODE_VISUAL_LINE) zle visual-line-mode ;;
	esac
	zvm_highlight clear
	zvm_select_vi_mode $ZVM_MODE_NORMAL ${1:-true}
}
zvm_find_and_move_cursor () {
	local char=$1 
	local count=${2:-1} 
	local forward=${3:-true} 
	local skip=${4:-false} 
	local cursor=$CURSOR 
	[[ -z $char ]] && return 1
	while :
	do
		if $forward
		then
			cursor=$((cursor+1)) 
			((cursor > $#BUFFER)) && break
		else
			cursor=$((cursor-1)) 
			((cursor < 0)) && break
		fi
		if [[ ${BUFFER[$cursor+1]} == $char ]]
		then
			count=$((count-1)) 
		fi
		((count == 0)) && break
	done
	[[ $count > 0 ]] && return 1
	if $skip
	then
		if $forward
		then
			cursor=$((cursor-1)) 
		else
			cursor=$((cursor+1)) 
		fi
	fi
	CURSOR=$cursor 
}
zvm_find_bindkey_widget () {
	local keymap=$1 
	local keys=$2 
	local prefix_mode=${3:-false} 
	retval=() 
	if $prefix_mode
	then
		local pos=0 
		local spos=3 
		local prefix_keys= 
		if [[ -n $prefix_keys ]]
		then
			prefix_keys=${prefix_keys:0:-1} 
			if [[ ${prefix_keys: -1} == '\' ]]
			then
				prefix_keys=${prefix_keys:0:-1} 
			fi
		fi
		local result=$(bindkey -M ${keymap} -p "$prefix_keys")$'\n' 
		for ((i=$spos; i<$#result; i++)) do
			case "${result:$i:1}" in
				(' ') spos=$i 
					i=$i+1 
					continue ;;
				([$'\n'])  ;;
				(*) continue ;;
			esac
			if [[ "${result:$((pos+1)):$#keys}" == "$keys" ]]
			then
				local k=${result:$((pos+1)):$((spos-pos-2))} 
				k=${k// /$ZVM_ESCAPE_SPACE} 
				retval+=($k ${result:$((spos+1)):$((i-spos-1))}) 
			fi
			pos=$i+1 
			i=$i+3 
		done
	else
		local result=$(bindkey -M ${keymap} "$keys") 
		if [[ "${result: -14}" == ' undefined-key' ]]
		then
			return
		fi
		for ((i=$#result; i>=0; i--)) do
			[[ "${result:$i:1}" == ' ' ]] || continue
			local k=${result:1:$i-2} 
			k=${k// /$ZVM_ESCAPE_SPACE} 
			retval+=($k ${result:$i+1}) 
			break
		done
	fi
}
zvm_forward_kill_line () {
	BUFFER=${BUFFER:0:$CURSOR} 
}
zvm_highlight () {
	local opt=${1:-mode} 
	local region=() 
	local redraw=false 
	case "$opt" in
		(mode) case "$ZVM_MODE" in
				($ZVM_MODE_VISUAL | $ZVM_MODE_VISUAL_LINE) local ret=($(zvm_calc_selection)) 
					local bpos=$((ret[1])) epos=$((ret[2])) 
					local bg=$ZVM_VI_HIGHLIGHT_BACKGROUND 
					local fg=$ZVM_VI_HIGHLIGHT_FOREGROUND 
					local es=$ZVM_VI_HIGHLIGHT_EXTRASTYLE 
					region=("$bpos $epos fg=$fg,bg=$bg,$es")  ;;
			esac
			redraw=true  ;;
		(custom) local bpos=$2 epos=$3 
			local bg=${4:-$ZVM_VI_HIGHLIGHT_BACKGROUND} 
			local fg=${5:-$ZVM_VI_HIGHLIGHT_FOREGROUND} 
			local es=${6:-$ZVM_VI_HIGHLIGHT_EXTRASTYLE} 
			region=("${ZVM_REGION_HIGHLIGHT[@]}") 
			region+=("$bpos $epos fg=$fg,bg=$bg,$es") 
			redraw=true  ;;
		(clear) zle redisplay
			redraw=true  ;;
		(redraw) redraw=true  ;;
	esac
	if (( $#region > 0 )) || [[ "$opt" == 'clear' ]]
	then
		local rawhighlight=() 
		for ((i=1; i<=${#region_highlight[@]}; i++)) do
			local raw=true 
			local spl=(${(@s/ /)region_highlight[i]}) 
			local pat="${spl[1]} ${spl[2]}" 
			for ((j=1; j<=${#ZVM_REGION_HIGHLIGHT[@]}; j++)) do
				if [[ "$pat" == "${ZVM_REGION_HIGHLIGHT[j]:0:$#pat}" ]]
				then
					raw=false 
					break
				fi
			done
			if $raw
			then
				rawhighlight+=("${region_highlight[i]}") 
			fi
		done
		ZVM_REGION_HIGHLIGHT=("${region[@]}") 
		region_highlight=("${rawhighlight[@]}" "${ZVM_REGION_HIGHLIGHT[@]}") 
	fi
	if $redraw
	then
		zle -R
	fi
}
zvm_init () {
	if $ZVM_INIT_DONE
	then
		return
	fi
	ZVM_INIT_DONE=true 
	zvm_exec_commands 'before_init'
	case $ZVM_READKEY_ENGINE in
		($ZVM_READKEY_ENGINE_NEX | $ZVM_READKEY_ENGINE_ZLE)  ;;
		(*) echo -n "Warning: Unsupported readkey engine! "
			echo "ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE"
			ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_DEFAULT  ;;
	esac
	case $ZVM_READKEY_ENGINE in
		($ZVM_READKEY_ENGINE_NEX) KEYTIMEOUT=1  ;;
		($ZVM_READKEY_ENGINE_ZLE) KEYTIMEOUT=$(($ZVM_KEYTIMEOUT*100))  ;;
	esac
	zvm_define_widget zvm_default_handler
	zvm_define_widget zvm_readkeys_handler
	zvm_define_widget zvm_backward_kill_region
	zvm_define_widget zvm_backward_kill_line
	zvm_define_widget zvm_forward_kill_line
	zvm_define_widget zvm_kill_line
	zvm_define_widget zvm_viins_undo
	zvm_define_widget zvm_select_surround
	zvm_define_widget zvm_change_surround
	zvm_define_widget zvm_move_around_surround
	zvm_define_widget zvm_change_surround_text_object
	zvm_define_widget zvm_enter_insert_mode
	zvm_define_widget zvm_exit_insert_mode
	zvm_define_widget zvm_enter_visual_mode
	zvm_define_widget zvm_exit_visual_mode
	zvm_define_widget zvm_enter_oppend_mode
	zvm_define_widget zvm_exit_oppend_mode
	zvm_define_widget zvm_exchange_point_and_mark
	zvm_define_widget zvm_open_line_below
	zvm_define_widget zvm_open_line_above
	zvm_define_widget zvm_insert_bol
	zvm_define_widget zvm_append_eol
	zvm_define_widget zvm_self_insert
	zvm_define_widget zvm_vi_replace
	zvm_define_widget zvm_vi_replace_chars
	zvm_define_widget zvm_vi_substitute
	zvm_define_widget zvm_vi_substitute_whole_line
	zvm_define_widget zvm_vi_change
	zvm_define_widget zvm_vi_change_eol
	zvm_define_widget zvm_vi_delete
	zvm_define_widget zvm_vi_yank
	zvm_define_widget zvm_vi_put_after
	zvm_define_widget zvm_vi_put_before
	zvm_define_widget zvm_vi_replace_selection
	zvm_define_widget zvm_vi_up_case
	zvm_define_widget zvm_vi_down_case
	zvm_define_widget zvm_vi_opp_case
	zvm_define_widget zvm_vi_edit_command_line
	zvm_define_widget zvm_repeat_change
	zvm_define_widget zvm_switch_keyword
	zvm_define_widget zle-line-pre-redraw zvm_zle-line-pre-redraw
	zvm_define_widget zle-line-init zvm_zle-line-init
	zvm_define_widget zle-line-finish zvm_zle-line-finish
	zvm_define_widget reset-prompt zvm_reset_prompt
	zvm_bindkey viins '^A' beginning-of-line
	zvm_bindkey viins '^E' end-of-line
	zvm_bindkey viins '^B' backward-char
	zvm_bindkey viins '^F' forward-char
	zvm_bindkey viins '^K' zvm_forward_kill_line
	zvm_bindkey viins '^W' backward-kill-word
	zvm_bindkey viins '^U' zvm_viins_undo
	zvm_bindkey viins '^Y' yank
	zvm_bindkey viins '^_' undo
	zvm_bindkey viins '^[[H' beginning-of-line
	zvm_bindkey vicmd '^[[H' beginning-of-line
	zvm_bindkey viins '^[[F' end-of-line
	zvm_bindkey vicmd '^[[F' end-of-line
	zvm_bindkey viins '^[[3~' delete-char
	zvm_bindkey vicmd '^[[3~' delete-char
	zvm_bindkey viins '^R' history-incremental-search-backward
	zvm_bindkey viins '^S' history-incremental-search-forward
	zvm_bindkey viins '^P' up-line-or-history
	zvm_bindkey viins '^N' down-line-or-history
	zvm_bindkey vicmd 'i' zvm_enter_insert_mode
	zvm_bindkey vicmd 'a' zvm_enter_insert_mode
	zvm_bindkey vicmd 'I' zvm_insert_bol
	zvm_bindkey vicmd 'A' zvm_append_eol
	zvm_bindkey vicmd 'v' zvm_enter_visual_mode
	zvm_bindkey vicmd 'V' zvm_enter_visual_mode
	zvm_bindkey visual 'o' zvm_exchange_point_and_mark
	zvm_bindkey vicmd 'o' zvm_open_line_below
	zvm_bindkey vicmd 'O' zvm_open_line_above
	zvm_bindkey vicmd 'r' zvm_vi_replace_chars
	zvm_bindkey vicmd 'R' zvm_vi_replace
	zvm_bindkey vicmd 's' zvm_vi_substitute
	zvm_bindkey vicmd 'S' zvm_vi_substitute_whole_line
	zvm_bindkey vicmd 'C' zvm_vi_change_eol
	zvm_bindkey visual 'c' zvm_vi_change
	zvm_bindkey visual 'd' zvm_vi_delete
	zvm_bindkey visual 'x' zvm_vi_delete
	zvm_bindkey visual 'y' zvm_vi_yank
	zvm_bindkey vicmd 'p' zvm_vi_put_after
	zvm_bindkey vicmd 'P' zvm_vi_put_before
	zvm_bindkey visual 'p' zvm_vi_replace_selection
	zvm_bindkey visual 'P' zvm_vi_replace_selection
	zvm_bindkey visual 'U' zvm_vi_up_case
	zvm_bindkey visual 'u' zvm_vi_down_case
	zvm_bindkey visual '~' zvm_vi_opp_case
	zvm_bindkey visual 'v' zvm_vi_edit_command_line
	zvm_bindkey vicmd '.' zvm_repeat_change
	zvm_bindkey vicmd '^A' zvm_switch_keyword
	zvm_bindkey vicmd '^X' zvm_switch_keyword
	local exit_oppend_mode_widget= 
	local exit_insert_mode_widget= 
	local exit_visual_mode_widget= 
	local default_handler_widget= 
	case $ZVM_READKEY_ENGINE in
		($ZVM_READKEY_ENGINE_NEX) exit_oppend_mode_widget=zvm_readkeys_handler 
			exit_insert_mode_widget=zvm_readkeys_handler 
			exit_visual_mode_widget=zvm_readkeys_handler  ;;
		($ZVM_READKEY_ENGINE_ZLE) exit_insert_mode_widget=zvm_exit_insert_mode 
			exit_visual_mode_widget=zvm_exit_visual_mode 
			default_handler_widget=zvm_default_handler  ;;
	esac
	zvm_bindkey vicmd "$ZVM_VI_OPPEND_ESCAPE_BINDKEY" $exit_oppend_mode_widget
	zvm_bindkey viins "$ZVM_VI_INSERT_ESCAPE_BINDKEY" $exit_insert_mode_widget
	zvm_bindkey visual "$ZVM_VI_VISUAL_ESCAPE_BINDKEY" $exit_visual_mode_widget
	case "$ZVM_VI_OPPEND_ESCAPE_BINDKEY" in
		('^[' | '\e')  ;;
		(*) zvm_bindkey vicmd '^[' $exit_oppend_mode_widget ;;
	esac
	case "$ZVM_VI_INSERT_ESCAPE_BINDKEY" in
		('^[' | '\e')  ;;
		(*) zvm_bindkey viins '^[' $exit_insert_mode_widget ;;
	esac
	case "$ZVM_VI_VISUAL_ESCAPE_BINDKEY" in
		('^[' | '\e')  ;;
		(*) zvm_bindkey visual '^[' $exit_visual_mode_widget ;;
	esac
	for c in {y,d,c}
	do
		zvm_bindkey vicmd "$c" $default_handler_widget
	done
	local surrounds=() 
	for s in ${(s..)^:-'()[]{}<>'}
	do
		surrounds+=($s) 
	done
	for s in {\',\",\`,\ ,'^['}
	do
		surrounds+=($s) 
	done
	if $is_custom_escape_key
	then
		surrounds+=("$ZVM_VI_ESCAPE_BINDKEY") 
	fi
	for s in $surrounds
	do
		for c in {a,i}${s}
		do
			zvm_bindkey visual "$c" zvm_select_surround
		done
		for c in {c,d,y}{a,i}${s}
		do
			zvm_bindkey vicmd "$c" zvm_change_surround_text_object
		done
		if [[ $ZVM_VI_SURROUND_BINDKEY == 's-prefix' ]]
		then
			for c in s{d,r}${s}
			do
				zvm_bindkey vicmd "$c" zvm_change_surround
			done
			for c in sa${s}
			do
				zvm_bindkey visual "$c" zvm_change_surround
			done
		else
			for c in {d,c}s${s}
			do
				zvm_bindkey vicmd "$c" zvm_change_surround
			done
			for c in {S,ys}${s}
			do
				zvm_bindkey visual "$c" zvm_change_surround
			done
		fi
	done
	zvm_bindkey vicmd '%' zvm_move_around_surround
	zvm_bindkey viins '^?' backward-delete-char
	bindkey -v
	zvm_exec_commands 'after_init'
}
zvm_insert_bol () {
	ZVM_INSERT_MODE='I' 
	zle vi-first-non-blank
	zvm_select_vi_mode $ZVM_MODE_INSERT
	zvm_reset_repeat_commands $ZVM_MODE_NORMAL $ZVM_INSERT_MODE
}
zvm_is_empty_line () {
	local cursor=${1:-$CURSOR} 
	if [[ ${BUFFER:$cursor:1} == $'\n' && ${BUFFER:$((cursor-1)):1} == $'\n' ]]
	then
		return
	fi
	return 1
}
zvm_keys () {
	local keys=${ZVM_KEYS:-$KEYS} 
	case "${ZVM_MODE}" in
		($ZVM_MODE_VISUAL) if [[ "$keys" != v* ]]
			then
				keys="v${keys}" 
			fi ;;
		($ZVM_MODE_VISUAL_LINE) if [[ "$keys" != V* ]]
			then
				keys="V${keys}" 
			fi ;;
	esac
	keys=${keys//$'\n'/$ZVM_ESCAPE_NEWLINE} 
	keys=${keys// /$ZVM_ESCAPE_SPACE} 
	echo $keys
}
zvm_kill_line () {
	local ret=($(zvm_calc_selection $ZVM_MODE_VISUAL_LINE)) 
	local bpos=${ret[1]} epos=${ret[2]} 
	CUTBUFFER=${BUFFER:$bpos:$((epos-bpos))}$'\n' 
	BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}" 
	CURSOR=$bpos 
}
zvm_kill_whole_line () {
	local ret=($(zvm_calc_selection $ZVM_MODE_VISUAL_LINE)) 
	local bpos=$ret[1] epos=$ret[2] cpos=$ret[3] 
	CUTBUFFER=${BUFFER:$bpos:$((epos-bpos))}$'\n' 
	if (( $epos < $#BUFFER ))
	then
		epos=$epos+1 
	fi
	BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}" 
	CURSOR=$cpos 
}
zvm_match_surround () {
	local bchar=${1// /$ZVM_ESCAPE_SPACE} 
	local echar=$bchar 
	case $bchar in
		('(') echar=')'  ;;
		('[') echar=']'  ;;
		('{') echar='}'  ;;
		('<') echar='>'  ;;
		(')') bchar='(' 
			echar=')'  ;;
		(']') bchar='[' 
			echar=']'  ;;
		('}') bchar='{' 
			echar='}'  ;;
		('>') bchar='<' 
			echar='>'  ;;
	esac
	echo $bchar $echar
}
zvm_move_around_surround () {
	local slen= 
	local bpos=-1 
	local epos=-1 
	for ((i=$CURSOR; i>=0; i--)) do
		for s in {\',\",\`,\(,\[,\{,\<}
		do
			slen=${#s} 
			if [[ ${BUFFER:$i:$slen} == "$s" ]]
			then
				bpos=$i 
				break
			fi
		done
		if (($bpos == -1))
		then
			continue
		fi
		local ret=($(zvm_search_surround "$s")) 
		if [[ -z ${ret[@]} ]]
		then
			continue
		fi
		bpos=${ret[1]} 
		epos=${ret[2]} 
		if (( $CURSOR > $((bpos-1)) )) && (( $CURSOR < $((bpos+slen)) ))
		then
			CURSOR=$epos 
		else
			CURSOR=$bpos 
		fi
		break
	done
}
zvm_navigation_handler () {
	[[ -z $1 ]] && return 1
	local keys=$1 
	local count= 
	local cmd= 
	if [[ $keys =~ '^([1-9][0-9]*)?([fFtT].?)$' ]]
	then
		count=${match[1]:-1} 
		if (( ${#match[2]} < 2))
		then
			zvm_enter_oppend_mode
			read -k 1 cmd
			keys+=$cmd 
			case "$(zvm_escape_non_printed_characters ${keys[-1]})" in
				($ZVM_VI_OPPEND_ESCAPE_BINDKEY) return 1 ;;
			esac
			zvm_exit_oppend_mode
		fi
		local forward=true 
		local skip=false 
		[[ ${keys[-2]} =~ '[FT]' ]] && forward=false 
		[[ ${keys[-2]} =~ '[tT]' ]] && skip=true 
		local key=${keys[-1]} 
		if [[ $key =~ "['\\\"\`\~\^\|\#\&\*\;\}\(\)\<\>\ ]" ]]
		then
			key=\\${key} 
		fi
		cmd=(zvm_find_and_move_cursor $key $count $forward $skip) 
		count=1 
	else
		count=${keys:0:-1} 
		case ${keys: -1} in
			('^') cmd=(zle vi-first-non-blank)  ;;
			('$') cmd=(zle vi-end-of-line)  ;;
			(' ') cmd=(zle vi-forward-char)  ;;
			('0') cmd=(zle vi-digit-or-beginning-of-line)  ;;
			('h') cmd=(zle vi-backward-char)  ;;
			('j') cmd=(zle down-line-or-history)  ;;
			('k') cmd=(zle up-line-or-history)  ;;
			('l') cmd=(zle vi-forward-char)  ;;
			('w') cmd=(zle vi-forward-word)  ;;
			('W') cmd=(zle vi-forward-blank-word)  ;;
			('e') cmd=(zle vi-forward-word-end)  ;;
			('E') cmd=(zle vi-forward-blank-word-end)  ;;
			('b') cmd=(zle vi-backward-word)  ;;
			('B') cmd=(zle vi-backward-blank-word)  ;;
		esac
	fi
	if [[ -z $cmd ]]
	then
		return 0
	fi
	if [[ ! $count =~ ^[0-9]+$ ]]
	then
		count=1 
	fi
	zvm_repeat_command "$cmd" $count
	exit_code=$? 
	if [[ $exit_code == 0 ]]
	then
		retval=$keys 
	fi
	return $exit_code
}
zvm_open_line_above () {
	local i=$CURSOR 
	for ((; i>0; i--)) do
		if [[ "${BUFFER[$i]}" == $'\n' ]]
		then
			break
		fi
	done
	CURSOR=$i 
	LBUFFER+=$'\n' 
	CURSOR=$((CURSOR-1)) 
	zvm_reset_repeat_commands $ZVM_MODE_NORMAL O
	zvm_select_vi_mode $ZVM_MODE_INSERT
}
zvm_open_line_below () {
	local i=$CURSOR 
	for ((; i<$#BUFFER; i++)) do
		if ((SUFFIX_ACTIVE == 1)) && ((i >= SUFFIX_BEGIN))
		then
			break
		fi
		if [[ "${BUFFER[$i]}" == $'\n' ]]
		then
			i=$((i-1)) 
			break
		fi
	done
	CURSOR=$i 
	LBUFFER+=$'\n' 
	zvm_reset_repeat_commands $ZVM_MODE_NORMAL o
	zvm_select_vi_mode $ZVM_MODE_INSERT
}
zvm_parse_surround_keys () {
	local keys=${1:-${$(zvm_keys)//$ZVM_ESCAPE_SPACE/ }} 
	local action= 
	local surround= 
	case "${keys}" in
		(vS*) action=S 
			surround=${keys:2}  ;;
		(vsa*) action=a 
			surround=${keys:3}  ;;
		(vys*) action=y 
			surround=${keys:3}  ;;
		(s[dr]*) action=${keys:1:1} 
			surround=${keys:2}  ;;
		([acd]s*) action=${keys:0:1} 
			surround=${keys:2}  ;;
		([cdvy][ia]*) action=${keys:0:2} 
			surround=${keys:2}  ;;
	esac
	echo $action ${surround// /$ZVM_ESCAPE_SPACE}
}
zvm_postpone_reset_prompt () {
	local toggle=$1 
	local force=$2 
	if [[ $force == true ]]
	then
		ZVM_POSTPONE_RESET_PROMPT=1 
	fi
	if $toggle
	then
		ZVM_POSTPONE_RESET_PROMPT=0 
	else
		if (($ZVM_POSTPONE_RESET_PROMPT > 0))
		then
			ZVM_POSTPONE_RESET_PROMPT=-1 
			zle reset-prompt
		else
			ZVM_POSTPONE_RESET_PROMPT=-1 
		fi
	fi
}
zvm_range_handler () {
	local keys=$1 
	local cursor=$CURSOR 
	local key= 
	local mode= 
	local cmds=($ZVM_MODE) 
	local count=1 
	local exit_code=0 
	zvm_enter_oppend_mode false
	while (( ${#keys} < 2 ))
	do
		zvm_update_cursor
		read -k 1 key
		keys="${keys}${key}" 
	done
	while [[ ${keys: 1} =~ ^[1-9][0-9]*$ ]]
	do
		zvm_update_cursor
		read -k 1 key
		keys="${keys}${key}" 
	done
	if [[ ${keys: -1} =~ [ia] ]]
	then
		zvm_update_cursor
		read -k 1 key
		keys="${keys}${key}" 
	fi
	zvm_exit_oppend_mode
	if [[ $(zvm_escape_non_printed_characters "$keys") =~ ${ZVM_VI_OPPEND_ESCAPE_BINDKEY/\^\[/\\^\\[} ]]
	then
		return 1
	fi
	if [[ $ZVM_MODE != $ZVM_MODE_VISUAL && $ZVM_MODE != $ZVM_MODE_VISUAL_LINE ]]
	then
		case "${keys}" in
			([cdy][jk]) mode=$ZVM_MODE_VISUAL_LINE  ;;
			(cc | dd | yy) mode=$ZVM_MODE_VISUAL_LINE  ;;
			(*) mode=$ZVM_MODE_VISUAL  ;;
		esac
		if [[ ! -z $mode ]]
		then
			zvm_select_vi_mode $mode false
		fi
	fi
	local navkey= 
	if [[ $keys =~ '^c([1-9][0-9]*)?[ia][wW]$' ]]
	then
		count=${match[1]:-1} 
		navkey=${keys: -2} 
	elif [[ $keys =~ '^[cdy]([1-9][0-9]*)?[ia][eE]$' ]]
	then
		navkey= 
	elif [[ $keys =~ '^c([1-9][0-9]*)?[eEwW]$' ]]
	then
		count=${match[1]:-1} 
		navkey=c${keys: -1} 
	elif [[ $keys =~ '^[cdy]([1-9][0-9]*)?[bB]$' ]]
	then
		MARK=$((MARK-1)) 
		count=${match[1]:-1} 
		navkey=${keys: -1} 
	elif [[ $keys =~ '^[cdy]([1-9][0-9]*)?([FT].?)$' ]]
	then
		MARK=$((MARK-1)) 
		count=${match[1]:-1} 
		navkey=${match[2]} 
	elif [[ $keys =~ '^[cdy]([1-9][0-9]*)?j$' ]]
	then
		count=${match[1]:-1} 
		for ((i=$((CURSOR+1)); i<=$#BUFFER; i++)) do
			[[ ${BUFFER[$i]} == $'\n' ]] && navkey='j' 
		done
	elif [[ $keys =~ '^[cdy]([1-9][0-9]*)?k$' ]]
	then
		count=${match[1]:-1} 
		for ((i=$((CURSOR+1)); i>0; i--)) do
			[[ ${BUFFER[$i]} == $'\n' ]] && navkey='k' 
		done
	elif [[ $keys =~ '^[cdy]([1-9][0-9]*)?[\^h0]$' ]]
	then
		MARK=$((MARK-1)) 
		count=${match[1]:-1} 
		navkey=${keys: -1} 
		if ((MARK < 0))
		then
			navkey= 
		elif [[ ${BUFFER[$MARK+1]} == $'\n' ]]
		then
			navkey= 
		fi
	elif [[ $keys =~ '^[cdy]([1-9][0-9]*)?l$' ]]
	then
		count=${match[1]:-1} 
		count=$((count-1)) 
		navkey=${count}l 
	elif [[ $keys =~ '^.([1-9][0-9]*)?([^0-9]+)$' ]]
	then
		count=${match[1]:-1} 
		navkey=${match[2]} 
	else
		navkey= 
	fi
	case $navkey in
		('') exit_code=1  ;;
		(*[ia]?) if [[ -z $count ]]
			then
				count=1 
			fi
			case ${navkey: -2} in
				(iw) cmd=(zle select-in-word)  ;;
				(aw) cmd=(zle select-a-word)  ;;
				(iW) cmd=(zle select-in-blank-word)  ;;
				(aW) cmd=(zle select-a-blank-word)  ;;
			esac
			zvm_repeat_command "$cmd" $count ;;
		(c[eEwW]) if [[ "${BUFFER[$((CURSOR + 1))]}" == ' ' ]]
			then
				case ${navkey: -1} in
					(w) cmd=(zle vi-forward-word)  ;;
					(W) cmd=(zle vi-forward-blank-word)  ;;
					(e) cmd=(zle vi-forward-word-end)  ;;
					(E) cmd=(zle vi-forward-blank-word-end)  ;;
				esac
				zvm_repeat_command "$cmd" $count
				case ${navkey: -1} in
					(w | W) CURSOR=$((CURSOR-1))  ;;
				esac
			else
				if [[ "${BUFFER[$((CURSOR + 2))]}" == ' ' ]]
				then
					count=$((count - 1)) 
				fi
				case ${navkey: -1} in
					(e | w) cmd=(zle vi-forward-word-end)  ;;
					(E | W) cmd=(zle vi-forward-blank-word-end)  ;;
				esac
				zvm_repeat_command "$cmd" $count
			fi ;;
		(*) local retval= 
			BUFFER+=$'\0' 
			if zvm_navigation_handler "${count}${navkey}"
			then
				keys="${keys[1]}${retval}" 
			else
				exit_code=1 
			fi
			BUFFER[-1]=''  ;;
	esac
	if [[ $exit_code != 0 ]]
	then
		zvm_exit_visual_mode
		return
	fi
	if [[ $keys =~ '^[cdy]([1-9][0-9]*)?[ia][wW]$' ]]
	then
		cursor=$MARK 
	elif [[ $keys =~ '[dy]([1-9][0-9]*)?[wW]' ]]
	then
		CURSOR=$((CURSOR-1)) 
		if [[ "${BUFFER:$CURSOR:1}" == $'\n' ]]
		then
			CURSOR=$((CURSOR-1)) 
		fi
	else
		cursor=$CURSOR 
	fi
	case "${keys}" in
		(c*) zvm_vi_change false
			cursor=  ;;
		(d*) zvm_vi_delete false
			cursor=  ;;
		(y*) zvm_vi_yank false
			cursor=  ;;
		([vV]*) cursor=  ;;
	esac
	if $ZVM_REPEAT_MODE
	then
		zvm_exit_visual_mode false
	elif [[ $keys =~ '^[cd].*' ]]
	then
		cmds+=($keys) 
		zvm_reset_repeat_commands $cmds
	fi
	if [[ ! -z $cursor ]]
	then
		CURSOR=$cursor 
	fi
}
zvm_readkeys () {
	local keymap=$1 
	local key=${2:-$(zvm_keys)} 
	local keys= 
	local widget= 
	local result= 
	local pattern= 
	local timeout= 
	while :
	do
		if [[ "$key" == $'\e' ]]
		then
			while :
			do
				local k= 
				read -t $ZVM_ESCAPE_KEYTIMEOUT -k 1 k || break
				key="${key}${k}" 
			done
		fi
		keys="${keys}${key}" 
		if [[ -n "$key" ]]
		then
			local k=$(zvm_escape_non_printed_characters "${key}") 
			k=${k//\"/\\\"} 
			k=${k//\`/\\\`} 
			k=${k//$ZVM_ESCAPE_SPACE/ } 
			pattern="${pattern}${k}" 
		fi
		zvm_find_bindkey_widget $keymap "$pattern" true
		result=(${retval[@]}) 
		case ${#result[@]} in
			(2) key= 
				widget=${result[2]} 
				break ;;
			(0) break ;;
		esac
		if [[ "${keys}" == $'\e' ]]
		then
			timeout=$ZVM_ESCAPE_KEYTIMEOUT 
			for ((i=1; i<=${#result[@]}; i=i+2)) do
				if [[ "${result[$i]}" =~ '^\^\[\[?[A-Z0-9]*~?\^\[' ]]
				then
					timeout=$ZVM_KEYTIMEOUT 
					break
				fi
			done
		else
			timeout=$ZVM_KEYTIMEOUT 
		fi
		key= 
		if [[ "${result[1]}" == "${pattern}" ]]
		then
			widget=${result[2]} 
			read -t $timeout -k 1 key || break
		else
			zvm_enter_oppend_mode
			read -k 1 key
		fi
	done
	if $ZVM_OPPEND_MODE
	then
		zvm_exit_oppend_mode
	fi
	if [[ -z "$key" ]]
	then
		retval=(${keys} $widget) 
	else
		retval=(${keys:0:-$#key} $widget $key) 
	fi
}
zvm_readkeys_handler () {
	local keymap=${1} 
	local keys=${2:-$KEYS} 
	local key= 
	local widget= 
	if [[ -z $keymap ]]
	then
		case "$ZVM_MODE" in
			($ZVM_MODE_INSERT) keymap=viins  ;;
			($ZVM_MODE_NORMAL) keymap=vicmd  ;;
			($ZVM_MODE_VISUAL | $ZVM_MODE_VISUAL_LINE) keymap=visual  ;;
		esac
	fi
	zvm_readkeys $keymap $keys
	keys=${retval[1]} 
	widget=${retval[2]} 
	key=${retval[3]} 
	keys=${keys//$ZVM_ESCAPE_SPACE/ } 
	key=${key//$ZVM_ESCAPE_SPACE/ } 
	ZVM_KEYS="${keys}" 
	if [[ "${widget}" == "${funcstack[1]}" ]]
	then
		widget= 
	fi
	if [[ -z ${widget} ]]
	then
		ZVM_RESET_PROMPT_DISABLED=true 
		zle zvm_default_handler "$key"
		ZVM_RESET_PROMPT_DISABLED=false 
		if [[ -n "$ZVM_KEYS" ]]
		then
			zle -U -- "${ZVM_KEYS}"
		else
			zvm_postpone_reset_prompt false
		fi
	else
		zle $widget
	fi
	ZVM_KEYS= 
}
zvm_repeat_change () {
	ZVM_REPEAT_MODE=true 
	ZVM_RESET_PROMPT_DISABLED=true 
	local cmd=${ZVM_REPEAT_COMMANDS[2]} 
	case $cmd in
		([aioAIO]) zvm_repeat_insert ;;
		(c) zvm_repeat_vi_change ;;
		([cd]*) zvm_repeat_range_change ;;
		(R) zvm_repeat_replace ;;
		(r) zvm_repeat_replace_chars ;;
		(*) zle vi-repeat-change ;;
	esac
	zle redisplay
	ZVM_RESET_PROMPT_DISABLED=false 
	ZVM_REPEAT_MODE=false 
}
zvm_repeat_command () {
	local cmd=$1 
	local count=${2:-1} 
	local is_zle_cmd=false 
	if [[ ${cmd} =~ '^zle .*' ]]
	then
		is_zle_cmd=true 
	fi
	local init_cursor=$CURSOR 
	local last_cursor=$CURSOR 
	local exit_code=0 
	for ((c=0; c<count; c++)) do
		eval $cmd
		exit_code=$? 
		if $is_zle_cmd
		then
			exit_code=0 
		elif [[ $exit_code != 0 ]]
		then
			CURSOR=$init_cursor 
			break
		fi
		[[ $last_cursor == $CURSOR ]] && break
		last_cursor=$CURSOR 
	done
	return $exit_code
}
zvm_repeat_insert () {
	local cmd=${ZVM_REPEAT_COMMANDS[2]} 
	local cmds=(${ZVM_REPEAT_COMMANDS[3,-1]}) 
	case $cmd in
		(a) CURSOR+=1  ;;
		(o) zle vi-backward-char
			zle vi-end-of-line
			LBUFFER+=$'\n'  ;;
		(A) zle vi-end-of-line
			CURSOR=$((CURSOR+1))  ;;
		(I) zle vi-first-non-blank ;;
		(O) zle vi-digit-or-beginning-of-line
			LBUFFER+=$'\n' 
			CURSOR=$((CURSOR-1))  ;;
	esac
	for ((i=1; i<=${#cmds[@]}; i++)) do
		cmd="${cmds[$i]}" 
		if [[ $cmd == '' ]]
		then
			if (($#LBUFFER > 0))
			then
				LBUFFER=${LBUFFER:0:-1} 
			fi
			continue
		fi
		if (($#cmd == 1))
		then
			LBUFFER+=$cmd 
		fi
	done
}
zvm_repeat_range_change () {
	local cmd=${ZVM_REPEAT_COMMANDS[2]} 
	zvm_range_handler $cmd
	zvm_repeat_insert
}
zvm_repeat_replace () {
	local cmds=(${ZVM_REPEAT_COMMANDS[3,-1]}) 
	local cmd= 
	local cursor=$CURSOR 
	for ((i=1; i<=${#cmds[@]}; i++)) do
		cmd="${cmds[$i]}" 
		if [[ $cmd == $'\n' || $BUFFER[$cursor+1] == $'\n' || $BUFFER[$cursor+1] == '' ]]
		then
			LBUFFER+=$cmd 
		else
			BUFFER[$cursor+1]=$cmd 
		fi
		cursor=$((cursor+1)) 
		CURSOR=$cursor 
	done
	zle vi-backward-char
}
zvm_repeat_replace_chars () {
	local mode=${ZVM_REPEAT_COMMANDS[1]} 
	local cmds=(${ZVM_REPEAT_COMMANDS[3,-1]}) 
	local cmd= 
	if [[ $mode == $ZVM_MODE_VISUAL_LINE ]]
	then
		zle vi-digit-or-beginning-of-line
		cmds+=($'\n') 
	fi
	local cursor=$((CURSOR+1)) 
	for ((i=1; i<=${#cmds[@]}; i++)) do
		cmd="${cmds[$i]}" 
		if [[ ${BUFFER[$cursor]} == $'\n' ]]
		then
			if [[ $cmd == $'\n' ]]
			then
				cursor=$((cursor+1)) 
			fi
			continue
		fi
		if [[ $cmd == $'\n' ]]
		then
			i=$((i-1)) 
			cmd="${cmds[$i]}" 
		fi
		if (($#cmd == 1))
		then
			BUFFER[$cursor]="${cmd}" 
		fi
		cursor=$((cursor+1)) 
		if ((cursor > $#BUFFER))
		then
			break
		fi
	done
}
zvm_repeat_vi_change () {
	local mode=${ZVM_REPEAT_COMMANDS[1]} 
	local cmds=(${ZVM_REPEAT_COMMANDS[3,-1]}) 
	if [[ $mode == $ZVM_MODE_VISUAL_LINE ]]
	then
		zle vi-digit-or-beginning-of-line
	fi
	local ncount=${cmds[1]} 
	local ccount=${cmds[2]} 
	local pos=$CURSOR epos=$CURSOR 
	for ((i=0; i<$ncount; i++)) do
		pos=$(zvm_substr_pos $BUFFER $'\n' $pos) 
		if [[ $pos == -1 ]]
		then
			epos=$#BUFFER 
			break
		fi
		pos=$((pos+1)) 
		epos=$pos 
	done
	for ((i=0; i<$ccount; i++)) do
		local char=${BUFFER[$epos+i]} 
		if [[ $char == $'\n' || $char == '' ]]
		then
			ccount=$i 
			break
		fi
	done
	epos=$((epos+ccount)) 
	RBUFFER=${RBUFFER:$((epos-CURSOR))} 
}
zvm_replace_selection () {
	local ret=($(zvm_calc_selection)) 
	local bpos=$ret[1] epos=$ret[2] cpos=$ret[3] 
	local cutbuf=$1 
	if (( $#cutbuf > 0 ))
	then
		cpos=$(($bpos + $#cutbuf - 1)) 
	fi
	CUTBUFFER=${BUFFER:$bpos:$((epos-bpos))} 
	if [[ $ZVM_MODE == $ZVM_MODE_VISUAL_LINE ]]
	then
		if (( $epos < $#BUFFER ))
		then
			epos=$epos+1 
		elif (( $bpos > 0 ))
		then
			bpos=$bpos-1 
		fi
		CUTBUFFER=${CUTBUFFER}$'\n' 
	fi
	BUFFER="${BUFFER:0:$bpos}${cutbuf}${BUFFER:$epos}" 
	CURSOR=$cpos 
}
zvm_reset_prompt () {
	if (($ZVM_POSTPONE_RESET_PROMPT >= 0))
	then
		ZVM_POSTPONE_RESET_PROMPT=$(($ZVM_POSTPONE_RESET_PROMPT + 1)) 
		return
	fi
	if [[ $ZVM_RESET_PROMPT_DISABLED == true ]]
	then
		return
	fi
	local -i retval
	if [[ -z "$rawfunc" ]]
	then
		zle .reset-prompt -- "$@"
	else
		$rawfunc -- "$@"
	fi
	return retval
}
zvm_reset_repeat_commands () {
	ZVM_REPEAT_RESET=true 
	ZVM_REPEAT_COMMANDS=($@) 
}
zvm_search_surround () {
	local ret=($(zvm_match_surround "$1")) 
	local bchar=${${ret[1]//$ZVM_ESCAPE_SPACE/ }:- } 
	local echar=${${ret[2]//$ZVM_ESCAPE_SPACE/ }:- } 
	local bpos=$(zvm_substr_pos $BUFFER $bchar $CURSOR false) 
	local epos=$(zvm_substr_pos $BUFFER $echar $CURSOR true) 
	if [[ $bpos == $epos ]]
	then
		epos=$(zvm_substr_pos $BUFFER $echar $((CURSOR+1)) true) 
		if [[ $epos == -1 ]]
		then
			epos=$(zvm_substr_pos $BUFFER $echar $((CURSOR-1)) false) 
			if [[ $epos != -1 ]]
			then
				local tmp=$epos 
				epos=$bpos 
				bpos=$tmp 
			fi
		fi
	fi
	if [[ $bpos == -1 ]] || [[ $epos == -1 ]]
	then
		return
	fi
	echo $bpos $epos $bchar $echar
}
zvm_select_in_word () {
	local cursor=${1:-$CURSOR} 
	local buffer=${2:-$BUFFER} 
	local bpos=$cursor epos=$cursor 
	local pattern='[0-9a-zA-Z_]' 
	if ! [[ "${buffer:$cursor:1}" =~ $pattern ]]
	then
		pattern="[^${pattern:1:-1} ]" 
	fi
	for ((; $bpos>=0; bpos--)) do
		[[ "${buffer:$bpos:1}" =~ $pattern ]] || break
	done
	for ((; $epos<$#buffer; epos++)) do
		[[ "${buffer:$epos:1}" =~ $pattern ]] || break
	done
	bpos=$((bpos+1)) 
	if (( epos > 0 ))
	then
		epos=$((epos-1)) 
	fi
	echo $bpos $epos
}
zvm_select_surround () {
	local ret=($(zvm_parse_surround_keys)) 
	local action=${ret[1]} 
	local surround=${ret[2]//$ZVM_ESCAPE_SPACE/ } 
	ret=($(zvm_search_surround ${surround})) 
	if [[ ${#ret[@]} == 0 ]]
	then
		zvm_exit_visual_mode
		return
	fi
	local bpos=${ret[1]} 
	local epos=${ret[2]} 
	if [[ ${action:1:1} == 'i' ]]
	then
		((bpos++))
	else
		((epos++))
	fi
	MARK=$bpos 
	CURSOR=$epos-1 
	zle reset-prompt
}
zvm_select_vi_mode () {
	local mode=$1 
	local reset_prompt=${2:-true} 
	if [[ $mode == "$ZVM_MODE" ]]
	then
		zvm_update_cursor
		return
	fi
	zvm_exec_commands 'before_select_vi_mode'
	zvm_postpone_reset_prompt true
	if $ZVM_OPPEND_MODE
	then
		zvm_exit_oppend_mode false
	fi
	case $mode in
		($ZVM_MODE_NORMAL) ZVM_MODE=$ZVM_MODE_NORMAL 
			zvm_update_cursor
			zle vi-cmd-mode ;;
		($ZVM_MODE_INSERT) ZVM_MODE=$ZVM_MODE_INSERT 
			zvm_update_cursor
			zle vi-insert ;;
		($ZVM_MODE_VISUAL) ZVM_MODE=$ZVM_MODE_VISUAL 
			zvm_update_cursor
			zle visual-mode ;;
		($ZVM_MODE_VISUAL_LINE) ZVM_MODE=$ZVM_MODE_VISUAL_LINE 
			zvm_update_cursor
			zle visual-line-mode ;;
		($ZVM_MODE_REPLACE) ZVM_MODE=$ZVM_MODE_REPLACE 
			zvm_enter_oppend_mode ;;
	esac
	zvm_exec_commands 'after_select_vi_mode'
	$reset_prompt && zvm_postpone_reset_prompt false
	if [[ $mode == $ZVM_MODE_NORMAL ]] && (( $#ZVM_LAZY_KEYBINDINGS_LIST > 0 ))
	then
		zvm_exec_commands 'before_lazy_keybindings'
		local list=("${ZVM_LAZY_KEYBINDINGS_LIST[@]}") 
		unset ZVM_LAZY_KEYBINDINGS_LIST
		for r in "${list[@]}"
		do
			eval "zvm_bindkey ${r}"
		done
		zvm_exec_commands 'after_lazy_keybindings'
	fi
}
zvm_selection () {
	local bpos= epos= 
	if (( MARK > CURSOR ))
	then
		bpos=$CURSOR epos=$((MARK+1)) 
	else
		bpos=$MARK epos=$((CURSOR+1)) 
	fi
	echo $bpos $epos
}
zvm_self_insert () {
	local keys=${1:-$KEYS} 
	if [[ ${POSTDISPLAY:0:$#keys} == $keys ]]
	then
		POSTDISPLAY=${POSTDISPLAY:$#keys} 
	else
		POSTDISPLAY= 
	fi
	LBUFFER+=${keys} 
}
zvm_set_cursor () {
	if [[ -n $VIMRUNTIME ]]
	then
		return
	fi
	echo -ne "$1"
}
zvm_string_to_hex () {
	local str= 
	for ((i=1; i<=$#1; i++)) do
		str+=$(printf '%x' "'${1[$i]}") 
	done
	echo "$str"
}
zvm_substr_pos () {
	local pos=-1 
	local len=${#1} 
	local slen=${#2} 
	local i=${3:-0} 
	local forward=${4:-true} 
	local init=${i:-$($forward && echo "$i" || echo "i=$len-1")} 
	local condition=$($forward && echo "i<$len" || echo "i>=0") 
	local step=$($forward && echo 'i++' || echo 'i--') 
	for (($init; $condition; $step)) do
		if [[ ${1:$i:$slen} == "$2" ]]
		then
			pos=$i 
			break
		fi
	done
	echo $pos
}
zvm_switch_boolean () {
	local word=$1 
	local increase=$2 
	local result= 
	local bpos=0 epos=$#word 
	if [[ $word =~ (^[+-]{0,2}) ]]
	then
		local prefix=${match[1]} 
		bpos=$mend 
		word=${word:$bpos} 
	fi
	case ${(L)word} in
		(true) result=false  ;;
		(false) result=true  ;;
		(yes) result=no  ;;
		(no) result=yes  ;;
		(on) result=off  ;;
		(off) result=on  ;;
		(y) result=n  ;;
		(n) result=y  ;;
		(t) result=f  ;;
		(f) result=t  ;;
		(*) return ;;
	esac
	if [[ $word =~ ^[A-Z]+$ ]]
	then
		result=${(U)result} 
	elif [[ $word =~ ^[A-Z] ]]
	then
		result=${(U)result:0:1}${result:1} 
	fi
	echo $result $bpos $epos
}
zvm_switch_keyword () {
	local bpos= epos= cpos=$CURSOR 
	if [[ ${BUFFER:$cpos:2} =~ [+-][0-9] ]]
	then
		if [[ $cpos == 0 || ${BUFFER:$((cpos-1)):1} =~ [^0-9] ]]
		then
			cpos=$((cpos+1)) 
		fi
	elif [[ ${BUFFER:$cpos:2} =~ [+-][a-zA-Z] ]]
	then
		if [[ $cpos == 0 || ${BUFFER:$((cpos-1)):1} == ' ' ]]
		then
			cpos=$((cpos+1)) 
		fi
	fi
	local result=($(zvm_select_in_word $cpos)) 
	bpos=${result[1]} epos=$((${result[2]}+1)) 
	if [[ $bpos != 0 && ${BUFFER:$((bpos-1)):1} == [+-] ]]
	then
		bpos=$((bpos-1)) 
	fi
	local word=${BUFFER:$bpos:$((epos-bpos))} 
	local keys=$(zvm_keys) 
	if [[ $keys == '' ]]
	then
		local increase=true 
	else
		local increase=false 
	fi
	for handler in $zvm_switch_keyword_handlers
	do
		if ! zvm_exist_command ${handler}
		then
			continue
		fi
		result=($($handler $word $increase)) 
		if (( $#result == 0 ))
		then
			continue
		fi
		epos=$(( bpos + ${result[3]} )) 
		bpos=$(( bpos + ${result[2]} )) 
		if (( cpos < bpos )) || (( cpos >= epos ))
		then
			continue
		fi
		zvm_switch_keyword_history+=("${handler}:${word}") 
		zvm_switch_keyword_history=("${zvm_switch_keyword_history[@]: -10}") 
		BUFFER="${BUFFER:0:$bpos}${result[1]}${BUFFER:$epos}" 
		CURSOR=$((bpos + ${#result[1]} - 1)) 
		zle reset-prompt
		return
	done
}
zvm_switch_month () {
	local word=$1 
	local increase=$2 
	local result=${(L)word} 
	local months=(january february march april may june july august september october november december) 
	local i=1 
	for ((; i<=${#months[@]}; i++)) do
		if [[ ${months[i]:0:$#result} == ${result} ]]
		then
			result=${months[i]} 
			break
		fi
	done
	if (( i > ${#months[@]} ))
	then
		return
	fi
	if $increase
	then
		if (( i == ${#months[@]} ))
		then
			i=1 
		else
			i=$((i+1)) 
		fi
	else
		if (( i == 1 ))
		then
			i=${#months[@]} 
		else
			i=$((i-1)) 
		fi
	fi
	local lastlen=0 
	local last="${zvm_switch_keyword_history[-1]}" 
	local funcmark="${funcstack[1]}:" 
	if [[ "$last" =~ "^${funcmark}" ]]
	then
		lastlen=$(($#last - $#funcmark)) 
	fi
	if [[ "$result" == "may" ]]
	then
		if (($lastlen == 3))
		then
			result=${months[i]:0:3} 
		else
			result=${months[i]} 
		fi
	else
		if (($#word == 3))
		then
			result=${months[i]:0:3} 
		else
			result=${months[i]} 
		fi
	fi
	if [[ $word =~ ^[A-Z]+$ ]]
	then
		result=${(U)result} 
	elif [[ $word =~ ^[A-Z] ]]
	then
		result=${(U)result:0:1}${result:1} 
	fi
	echo $result 0 $#word
}
zvm_switch_number () {
	local word=$1 
	local increase=${2:-true} 
	local result= bpos= epos= 
	if [[ $word =~ [^0-9]?(0[xX][0-9a-fA-F]*) ]]
	then
		local number=${match[1]} 
		local prefix=${number:0:2} 
		bpos=$((mbegin-1)) epos=$mend 
		local lower=true 
		if [[ $number =~ [A-Z][0-9]*$ ]]
		then
			lower=false 
		fi
		if (( $#number > 17 ))
		then
			local d=$(($#number - 15)) 
			local h=${number:0:$d} 
			number="0x${number:$d}" 
		fi
		local p=$(($#number - 2)) 
		if $increase
		then
			if (( $number == 0x${(l:15::f:)} ))
			then
				h=$(([##16]$h+1)) 
				h=${h: -1} 
				number=${(l:15::0:)} 
			else
				h=${h:2} 
				number=$(([##16]$number + 1)) 
			fi
		else
			if (( $number == 0 ))
			then
				if (( ${h:-0} == 0 ))
				then
					h=f 
				else
					h=$(([##16]$h-1)) 
					h=${h: -1} 
				fi
				number=${(l:15::f:)} 
			else
				h=${h:2} 
				number=$(([##16]$number - 1)) 
			fi
		fi
		if (( $#number < $p ))
		then
			number=${(l:$p::0:)number} 
		fi
		result="${h}${number}" 
		if $lower
		then
			result="${(L)result}" 
		fi
		result="${prefix}${result}" 
	elif [[ $word =~ [^0-9]?(0[bB][01]*) ]]
	then
		local number=${match[1]} 
		local prefix=${number:0:2} 
		bpos=$((mbegin-1)) epos=$mend 
		if (( $#number > 65 ))
		then
			local d=$(($#number - 63)) 
			local h=${number:0:$d} 
			number="0b${number:$d}" 
		fi
		local p=$(($#number - 2)) 
		if $increase
		then
			if (( $number == 0b${(l:63::1:)} ))
			then
				h=$(([##2]$h+1)) 
				h=${h: -1} 
				number=${(l:63::0:)} 
			else
				h=${h:2} 
				number=$(([##2]$number + 1)) 
			fi
		else
			if (( $number == 0b0 ))
			then
				if (( ${h:-0} == 0 ))
				then
					h=1 
				else
					h=$(([##2]$h-1)) 
					h=${h: -1} 
				fi
				number=${(l:63::1:)} 
			else
				h=${h:2} 
				number=$(([##2]$number - 1)) 
			fi
		fi
		if (( $#number < $p ))
		then
			number=${(l:$p::0:)number} 
		fi
		result="${prefix}${number}" 
	elif [[ $word =~ ([-+]?[0-9]+) ]]
	then
		local number=${match[1]} 
		bpos=$((mbegin-1)) epos=$mend 
		if $increase
		then
			result=$(($number + 1)) 
		else
			result=$(($number - 1)) 
		fi
		if [[ ${word:$bpos:1} == '+' ]]
		then
			result="+${result}" 
		fi
	fi
	if [[ -n $result ]]
	then
		echo $result $bpos $epos
	fi
}
zvm_switch_operator () {
	local word=$1 
	local increase=$2 
	local result= 
	case ${(L)word} in
		('&&') result='||'  ;;
		('||') result='&&'  ;;
		('++') result='--'  ;;
		('--') result='++'  ;;
		('==') result='!='  ;;
		('!=') result='=='  ;;
		('===') result='!=='  ;;
		('!==') result='==='  ;;
		('+') result='-'  ;;
		('-') result='*'  ;;
		('*') result='/'  ;;
		('/') result='+'  ;;
		('and') result='or'  ;;
		('or') result='and'  ;;
		(*) return ;;
	esac
	if [[ $word =~ ^[A-Z]+$ ]]
	then
		result=${(U)result} 
	elif [[ $word =~ ^[A-Z] ]]
	then
		result=${(U)result:0:1}${result:1} 
	fi
	printf "%s 0 $#word" "${result}"
}
zvm_switch_weekday () {
	local word=$1 
	local increase=$2 
	local result=${(L)word} 
	local weekdays=(sunday monday tuesday wednesday thursday friday saturday) 
	local i=1 
	for ((; i<=${#weekdays[@]}; i++)) do
		if [[ ${weekdays[i]:0:$#result} == ${result} ]]
		then
			result=${weekdays[i]} 
			break
		fi
	done
	if (( i > ${#weekdays[@]} ))
	then
		return
	fi
	if $increase
	then
		if (( i == ${#weekdays[@]} ))
		then
			i=1 
		else
			i=$((i+1)) 
		fi
	else
		if (( i == 1 ))
		then
			i=${#weekdays[@]} 
		else
			i=$((i-1)) 
		fi
	fi
	if (( $#result == $#word ))
	then
		result=${weekdays[i]} 
	else
		result=${weekdays[i]:0:$#word} 
	fi
	if [[ $word =~ ^[A-Z]+$ ]]
	then
		result=${(U)result} 
	elif [[ $word =~ ^[A-Z] ]]
	then
		result=${(U)result:0:1}${result:1} 
	fi
	echo $result 0 $#word
}
zvm_system_report () {
	local os_info= 
	case "$(uname -s)" in
		(Darwin) local product="$(sw_vers -productName)" 
			local version="$(sw_vers -productVersion) ($(sw_vers -buildVersion))" 
			os_info="${product} ${version}"  ;;
		(*) os_info="$(uname -s) ($(uname -r) $(uname -v) $(uname -m) $(uname -o))"  ;;
	esac
	local term_info="${TERM_PROGRAM:-unknown} ${TERM_PROGRAM_VERSION:-unknown}" 
	term_info="${term_info} (${TERM})" 
	local zsh_frameworks=() 
	if zvm_exist_command "omz"
	then
		zsh_framworks+=("oh-my-zsh $(omz version)") 
	fi
	if zvm_exist_command "starship"
	then
		zsh_framworks+=("$(starship --version | head -n 1)") 
	fi
	if zvm_exist_command "antigen"
	then
		zsh_framworks+=("$(antigen version | head -n 1)") 
	fi
	if zvm_exist_command "zplug"
	then
		zsh_framworks+=("zplug $(zplug --version | head -n 1)") 
	fi
	if zvm_exist_command "zinit"
	then
		local version=$(zinit version \
      | head -n 1 \
      | sed -E $'s/(\033\[[a-zA-Z0-9;]+ ?m)//g') 
		zsh_framworks+=("${version}") 
	fi
	local shell=$SHELL 
	if [[ -z $shell ]]
	then
		shell=zsh 
	fi
	print - "- Terminal program: ${term_info}"
	print - "- Operating system: ${os_info}"
	print - "- ZSH framework: ${(j:, :)zsh_framworks}"
	print - "- ZSH version: $($shell --version)"
	print - "- ZVM version: $(zvm_version | head -n 1)"
}
zvm_update_cursor () {
	$ZVM_CURSOR_STYLE_ENABLED || return
	local mode=$1 
	local shape= 
	if $ZVM_OPPEND_MODE
	then
		mode=opp 
		shape=$(zvm_cursor_style $ZVM_OPPEND_MODE_CURSOR) 
	fi
	case "${mode:-$ZVM_MODE}" in
		($ZVM_MODE_NORMAL) shape=$(zvm_cursor_style $ZVM_NORMAL_MODE_CURSOR)  ;;
		($ZVM_MODE_INSERT) shape=$(zvm_cursor_style $ZVM_INSERT_MODE_CURSOR)  ;;
		($ZVM_MODE_VISUAL) shape=$(zvm_cursor_style $ZVM_VISUAL_MODE_CURSOR)  ;;
		($ZVM_MODE_VISUAL_LINE) shape=$(zvm_cursor_style $ZVM_VISUAL_LINE_MODE_CURSOR)  ;;
	esac
	if [[ -n $shape ]]
	then
		zvm_set_cursor $shape
	fi
}
zvm_update_highlight () {
	case "$ZVM_MODE" in
		($ZVM_MODE_VISUAL | $ZVM_MODE_VISUAL_LINE) zvm_highlight ;;
	esac
}
zvm_update_repeat_commands () {
	$ZVM_REPEAT_MODE && return
	if $ZVM_REPEAT_RESET
	then
		ZVM_REPEAT_RESET=false 
		return
	fi
	[[ $ZVM_MODE == $ZVM_MODE_INSERT ]] || return
	local char=$KEYS 
	if [[ "$KEYS" =~ '\[[ABCD]' ]]
	then
		if [[ ${ZVM_REPEAT_COMMANDS[-1]} =~ '\[[ABCD]' ]]
		then
			ZVM_REPEAT_COMMANDS=(${ZVM_REPEAT_COMMANDS[@]:0:-1}) 
		fi
	else
		if [[ ${ZVM_REPEAT_COMMANDS[-1]} =~ '\[[ABCD]' ]]
		then
			zvm_reset_repeat_commands $ZVM_MODE_NORMAL i
		fi
		char=${BUFFER[$CURSOR]} 
	fi
	if [[ "$KEYS" == '' ]]
	then
		if ((${#ZVM_REPEAT_COMMANDS[@]} > 2)) && [[ ${ZVM_REPEAT_COMMANDS[-1]} != '' ]]
		then
			ZVM_REPEAT_COMMANDS=(${ZVM_REPEAT_COMMANDS[@]:0:-1}) 
		elif (($#LBUFFER > 0))
		then
			ZVM_REPEAT_COMMANDS+=($KEYS) 
		fi
	else
		ZVM_REPEAT_COMMANDS+=($char) 
	fi
}
zvm_version () {
	local git_info=$(git show -s --format="(%h, %ci)" 2>/dev/null) 
	echo -e "$ZVM_NAME $ZVM_VERSION $git_info"
	echo -e "\e[4m$ZVM_REPOSITORY\e[0m"
	echo -e "$ZVM_DESCRIPTION"
}
zvm_vi_change () {
	local ret=($(zvm_calc_selection)) 
	local bpos=$ret[1] epos=$ret[2] 
	CUTBUFFER=${BUFFER:$bpos:$((epos-bpos))} 
	if [[ $ZVM_MODE == $ZVM_MODE_VISUAL_LINE ]]
	then
		CUTBUFFER=${CUTBUFFER}$'\n' 
	fi
	BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}" 
	CURSOR=$bpos 
	$ZVM_REPEAT_MODE && return
	if [[ $ZVM_MODE != $ZVM_MODE_NORMAL ]]
	then
		local npos=0 ncount=0 ccount=0 
		while :
		do
			npos=$(zvm_substr_pos $CUTBUFFER $'\n' $npos) 
			if [[ $npos == -1 ]]
			then
				if (($ncount == 0))
				then
					ccount=$#CUTBUFFER 
				fi
				break
			fi
			npos=$((npos+1)) 
			ncount=$(($ncount + 1)) 
			ccount=$(($#CUTBUFFER - $npos)) 
		done
		zvm_reset_repeat_commands $ZVM_MODE c $ncount $ccount
	fi
	zvm_exit_visual_mode false
	zvm_select_vi_mode $ZVM_MODE_INSERT ${1:-true}
}
zvm_vi_change_eol () {
	local bpos=$CURSOR epos=$CURSOR 
	for ((; $epos<$#BUFFER; epos++)) do
		if [[ "${BUFFER:$epos:1}" == $'\n' ]]
		then
			break
		fi
	done
	CUTBUFFER=${BUFFER:$bpos:$((epos-bpos))} 
	BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}" 
	zvm_reset_repeat_commands $ZVM_MODE c 0 $#CUTBUFFER
	zvm_select_vi_mode $ZVM_MODE_INSERT
}
zvm_vi_delete () {
	zvm_replace_selection
	zvm_exit_visual_mode ${1:-true}
}
zvm_vi_down_case () {
	local ret=($(zvm_selection)) 
	local bpos=${ret[1]} epos=${ret[2]} 
	local content=${BUFFER:$bpos:$((epos-bpos))} 
	BUFFER="${BUFFER:0:$bpos}${(L)content}${BUFFER:$epos}" 
	zvm_exit_visual_mode
}
zvm_vi_edit_command_line () {
	local tmp_file=$(mktemp ${ZVM_TMPDIR}/zshXXXXXX) 
	echo "$BUFFER" >| "$tmp_file"
	"${(@Q)${(z)${ZVM_VI_EDITOR}}}" $tmp_file < /dev/tty
	BUFFER=$(cat $tmp_file) 
	rm "$tmp_file"
	case $ZVM_MODE in
		($ZVM_MODE_VISUAL | $ZVM_MODE_VISUAL_LINE) zvm_exit_visual_mode ;;
	esac
}
zvm_vi_opp_case () {
	local ret=($(zvm_selection)) 
	local bpos=${ret[1]} epos=${ret[2]} 
	local content=${BUFFER:$bpos:$((epos-bpos))} 
	for ((i=1; i<=$#content; i++)) do
		if [[ ${content[i]} =~ [A-Z] ]]
		then
			content[i]=${(L)content[i]} 
		elif [[ ${content[i]} =~ [a-z] ]]
		then
			content[i]=${(U)content[i]} 
		fi
	done
	BUFFER="${BUFFER:0:$bpos}${content}${BUFFER:$epos}" 
	zvm_exit_visual_mode
}
zvm_vi_put_after () {
	local head= foot= 
	local content=${CUTBUFFER} 
	local offset=1 
	if [[ ${content: -1} == $'\n' ]]
	then
		local pos=${CURSOR} 
		for ((; $pos<$#BUFFER; pos++)) do
			if [[ ${BUFFER:$pos:1} == $'\n' ]]
			then
				pos=$pos+1 
				break
			fi
		done
		if zvm_is_empty_line
		then
			head=${BUFFER:0:$pos} 
			foot=${BUFFER:$pos} 
		else
			head=${BUFFER:0:$pos} 
			foot=${BUFFER:$pos} 
			if [[ $pos == $#BUFFER ]]
			then
				content=$'\n'${content:0:-1} 
				pos=$pos+1 
			fi
		fi
		offset=0 
		BUFFER="${head}${content}${foot}" 
		CURSOR=$pos 
	else
		if zvm_is_empty_line
		then
			head="${BUFFER:0:$((CURSOR-1))}" 
			foot="${BUFFER:$CURSOR}" 
		else
			head="${BUFFER:0:$CURSOR}" 
			foot="${BUFFER:$((CURSOR+1))}" 
		fi
		BUFFER="${head}${BUFFER:$CURSOR:1}${content}${foot}" 
		CURSOR=$CURSOR+$#content 
	fi
	zvm_highlight clear
	zvm_highlight custom $(($#head+$offset)) $(($#head+$#content+$offset))
}
zvm_vi_put_before () {
	local head= foot= 
	local content=${CUTBUFFER} 
	if [[ ${content: -1} == $'\n' ]]
	then
		local pos=$CURSOR 
		for ((; $pos>0; pos--)) do
			if [[ "${BUFFER:$pos:1}" == $'\n' ]]
			then
				pos=$pos+1 
				break
			fi
		done
		if zvm_is_empty_line
		then
			head=${BUFFER:0:$((pos-1))} 
			foot=$'\n'${BUFFER:$pos} 
			pos=$((pos-1)) 
		else
			head=${BUFFER:0:$pos} 
			foot=${BUFFER:$pos} 
		fi
		BUFFER="${head}${content}${foot}" 
		CURSOR=$pos 
	else
		head="${BUFFER:0:$CURSOR}" 
		foot="${BUFFER:$((CURSOR+1))}" 
		BUFFER="${head}${content}${BUFFER:$CURSOR:1}${foot}" 
		CURSOR=$CURSOR+$#content 
		CURSOR=$((CURSOR-1)) 
	fi
	zvm_highlight clear
	zvm_highlight custom $#head $(($#head+$#content))
}
zvm_vi_replace () {
	if [[ $ZVM_MODE == $ZVM_MODE_NORMAL ]]
	then
		local cursor=$CURSOR 
		local cache=() 
		local cmds=() 
		local key= 
		zvm_select_vi_mode $ZVM_MODE_REPLACE
		while :
		do
			zvm_update_cursor
			zle -R
			read -k 1 key
			case $(zvm_escape_non_printed_characters $key) in
				('^[' | $ZVM_VI_OPPEND_ESCAPE_BINDKEY) break ;;
				('^M') key=$'\n'  ;;
			esac
			if [[ $key == '' ]]
			then
				if ((cursor > 0))
				then
					cursor=$((cursor-1)) 
				fi
				if ((${#cache[@]} > 0))
				then
					key=${cache[-1]} 
					if [[ $key == '<I>' ]]
					then
						key= 
					fi
					cache=(${cache[@]:0:-1}) 
					BUFFER[$cursor+1]=$key 
					cmds=(${cmds[@]:0:-1}) 
				fi
			else
				if [[ $key == $'\n' || $BUFFER[$cursor+1] == $'\n' || $BUFFER[$cursor+1] == '' ]]
				then
					cache+=('<I>') 
					LBUFFER+=$key 
				else
					cache+=(${BUFFER[$cursor+1]}) 
					BUFFER[$cursor+1]=$key 
				fi
				cursor=$((cursor+1)) 
				cmds+=($key) 
			fi
			CURSOR=$cursor 
			zle redisplay
		done
		zle vi-backward-char
		zvm_select_vi_mode $ZVM_MODE_NORMAL
		zvm_reset_repeat_commands $ZVM_MODE R $cmds
	elif [[ $ZVM_MODE == $ZVM_MODE_VISUAL ]]
	then
		zvm_enter_visual_mode V
		zvm_vi_change
	elif [[ $ZVM_MODE == $ZVM_MODE_VISUAL_LINE ]]
	then
		zvm_vi_change
	fi
}
zvm_vi_replace_chars () {
	local cmds=() 
	local key= 
	zvm_enter_oppend_mode
	zle redisplay
	zle -R
	read -k 1 key
	zvm_exit_oppend_mode
	case $(zvm_escape_non_printed_characters $key) in
		($ZVM_VI_OPPEND_ESCAPE_BINDKEY) zvm_exit_visual_mode
			return ;;
	esac
	if [[ $ZVM_MODE == $ZVM_MODE_NORMAL ]]
	then
		cmds+=($key) 
		BUFFER[$CURSOR+1]=$key 
	else
		local ret=($(zvm_calc_selection)) 
		local bpos=${ret[1]} epos=${ret[2]} 
		for ((bpos=bpos+1; bpos<=epos; bpos++)) do
			if [[ $BUFFER[$bpos] == $'\n' ]]
			then
				cmds+=($'\n') 
				continue
			fi
			cmds+=($key) 
			BUFFER[$bpos]=$key 
		done
		zvm_exit_visual_mode
	fi
	zvm_reset_repeat_commands $ZVM_MODE r $cmds
}
zvm_vi_replace_selection () {
	zvm_replace_selection $CUTBUFFER
	zvm_exit_visual_mode ${1:-true}
}
zvm_vi_substitute () {
	if [[ $ZVM_MODE == $ZVM_MODE_NORMAL ]]
	then
		BUFFER="${BUFFER:0:$CURSOR}${BUFFER:$((CURSOR+1))}" 
		zvm_reset_repeat_commands $ZVM_MODE c 0 1
		zvm_select_vi_mode $ZVM_MODE_INSERT
	else
		zvm_vi_change
	fi
}
zvm_vi_substitute_whole_line () {
	zvm_select_vi_mode $ZVM_MODE_VISUAL_LINE false
	zvm_vi_substitute
}
zvm_vi_up_case () {
	local ret=($(zvm_selection)) 
	local bpos=${ret[1]} epos=${ret[2]} 
	local content=${BUFFER:$bpos:$((epos-bpos))} 
	BUFFER="${BUFFER:0:$bpos}${(U)content}${BUFFER:$epos}" 
	zvm_exit_visual_mode
}
zvm_vi_yank () {
	zvm_yank
	zvm_exit_visual_mode ${1:-true}
}
zvm_viins_undo () {
	if [[ -n $ZVM_VI_INS_LEGACY_UNDO ]]
	then
		zvm_kill_line
	else
		zvm_backward_kill_line
	fi
}
zvm_widget_wrapper () {
	local rawfunc=$1 
	local func=$2 
	local -i retval
	$rawfunc "${@:3}"
	$func "${@:3}"
	return retval
}
zvm_yank () {
	local ret=($(zvm_calc_selection $1)) 
	local bpos=$ret[1] epos=$ret[2] cpos=$ret[3] 
	CUTBUFFER=${BUFFER:$bpos:$((epos-bpos))} 
	if [[ ${1:-$ZVM_MODE} == $ZVM_MODE_VISUAL_LINE ]]
	then
		CUTBUFFER=${CUTBUFFER}$'\n' 
	fi
	CURSOR=$bpos MARK=$epos 
}
zvm_zle-line-finish () {
	local shape=$(zvm_cursor_style $ZVM_CURSOR_USER_DEFAULT) 
	zvm_set_cursor $shape
	zvm_switch_keyword_history=() 
}
zvm_zle-line-init () {
	local mode=${ZVM_MODE:-$ZVM_MODE_INSERT} 
	zvm_select_vi_mode $ZVM_MODE_INSERT false
	case ${ZVM_LINE_INIT_MODE:-$mode} in
		($ZVM_MODE_INSERT) zvm_select_vi_mode $ZVM_MODE_INSERT ;;
		(*) zvm_select_vi_mode $ZVM_MODE_NORMAL ;;
	esac
}
zvm_zle-line-pre-redraw () {
	if [[ -n $TMUX ]]
	then
		zvm_update_cursor
		[[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]] && zle redisplay
	fi
	zvm_update_highlight
	zvm_update_repeat_commands
}
# Shell Options
setopt nohashdirs
setopt nolistbeep
setopt login
setopt promptsubst
# Aliases
alias -- byeconnect='overmind connect web'
alias -- config='/usr/bin/git --git-dir=/Users/jschuss/.dotfiles/ --work-tree=/Users/jschuss'
alias -- fixconflicts='nvim +Conflicted'
alias -- gcplast='git log -1 --pretty=format:"%H" | pbcopy'
alias -- gct='git checkout'
alias -- git=/opt/homebrew/bin/git
alias -- grmerged='git branch --merged | egrep -v "(^\*|master|dev|main)" | xargs git branch -d'
alias -- grremote='git fetch -p && git branch -vv | awk '\''/: gone]/{print }'\'' | xargs git branch -d'
alias -- icloud='~/Library/Mobile\ Documents/com~apple~CloudDocs/'
alias -- linter='bundle exec rubocop -A && bundle exec rspec --format documentation --exclude "spec/features/**/*" && bundle exec rspec spec/features --format documentation'
alias -- n='~/noted/noted'
alias -- noted='~/noted/noted'
alias -- openall='vim -o '
alias -- python=/opt/homebrew/bin/python3
alias -- rdm='rake db:migrate'
alias -- rdms='rake db:migrate:status'
alias -- rdr='rake db:rollback'
alias -- reef='cd ~/Brightline/reef'
alias -- rgvim=rg_vim
alias -- run-help=man
alias -- ss='pngpaste "./screenshot_$(date +%Y%m%d_%H%M%S).png"'
alias -- v=nvim
alias -- vim=nvim
alias -- vlvl='nvim $(fzf)'
alias -- which-command=whence
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/opt/homebrew/Cellar/ripgrep/13.0.0/bin/rg'
fi
export PATH=/Users/jschuss/.asdf/plugins/nodejs/shims\:/Users/jschuss/.asdf/installs/nodejs/22.14.0/bin\:/Users/jschuss/.local/bin\:/Users/jschuss/.asdf/shims\:/opt/homebrew/opt/asdf/libexec/bin\:/Users/jschuss/bin\:/Users/jschuss/.bin\:/Users/jschuss/usr/local/opt/go/libexec/bin\:/Users/jschuss/.yarn/bin\:/opt/homebrew/bin\:/usr/local/bin\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/Library/Apple/usr/bin
