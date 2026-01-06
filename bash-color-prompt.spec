%bcond tests 0

Name:           bash-color-prompt
Version:        %(cat VERSION)
Release:        0.1%{?dist}
Summary:        Customization Color prompt for Bash

License:        GPL-3.0-or-later
URL:            https://github.com/juhp/bash-color-prompt
Source0:        bash-color-prompt.sh
Source1:        bcp-profile.sh
Source2:        README.md
Source3:        COPYING
Source4:        example.bashrc.sh
BuildArch:      noarch
BuildRequires:  perl
%if %{with tests}
BuildRequires:  bats
BuildRequires:  git-core
BuildRequires:  hostname
%endif

%description
A flexible customizable Bash prompt framework.


%prep
%setup -c -T
cp -p %{SOURCE0} %{SOURCE1} %{SOURCE2} %{SOURCE3} %{SOURCE4} .


%build
sed -i -e "s/@BASHCOLORVERSION@/%{version}/" bash-color-prompt.sh

source ./bash-color-prompt.sh
bcp_static _bcp_static_layout
export PS1
perl -i -pe 's/\@BCP_STATIC_PS1\@/$ENV{PS1}/' bcp-profile.sh


%install
%global profiledir %{_sysconfdir}/profile.d
mkdir -p %{buildroot}%{profiledir}
install -m 644 bcp-profile.sh %{buildroot}%{profiledir}/bash-color-prompt.sh
mkdir -p %{buildroot}%{_datadir}/bash-color-prompt
install -m 644 bash-color-prompt.sh %{buildroot}%{_datadir}/bash-color-prompt/bcp.sh


%check
%if %{with tests}
mkdir -p tests
cd tests
cp  %{SOURCE10} .
BASH_COLOR_PROMPT_DIR=%{buildroot}%{profiledir} bats --timing --gather-test-outputs-in logs .
%endif


%files
%license COPYING
%doc README.md
%doc example.bashrc.sh
%{profiledir}/bash-color-prompt.sh
%dir %{_datadir}/bash-color-prompt
%{_datadir}/bash-color-prompt/bcp.sh


%changelog
* Wed Jan 07 2026 Jens Petersen <petersen@redhat.com> - 0.92-0.1
- profile: generate static PS1 at buildtime

* Tue Jan 06 2026 Jens Petersen <petersen@redhat.com> - 0.90-0.1
- initial package of major new version
