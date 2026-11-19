'use strict';
'require view';
'require fs';
'require ui';

return view.extend({
	runDiagReport: function() {
		return fs.exec_direct('/usr/bin/openwrt-diag', []).then(function(out) {
			if (out && out.length > 32)
				return out;
			return fs.exec('/usr/bin/openwrt-diag', []).then(function(res) {
				if (res && res.stdout && res.stdout.length > 32)
					return res.stdout;
				return fs.read_direct('/tmp/openwrt-diag-latest.txt');
			});
		}).catch(function(err) {
			return fs.exec('/usr/bin/openwrt-diag', []).then(function(res) {
				return (res && res.stdout) ? res.stdout : '诊断脚本执行返回为空';
			}).catch(function(err2) {
				return '诊断脚本执行失败: ' + (err2 && err2.message ? err2.message : String(err));
			});
		});
	},

	load: function() {
		return this.runDiagReport();
	},

	render: function(reportText) {
		var textarea = E('textarea', {
			'id': 'diag-report-textarea',
			'readonly': 'readonly',
			'style': 'width: 100%; height: 620px; font-family: monospace; font-size: 12.5px; line-height: 1.45; background: #1e1e2e; color: #cdd6f4; padding: 14px; border-radius: 8px; border: 1px solid #45475a; resize: vertical; white-space: pre;'
		}, [ reportText || '正在生成诊断报告...' ]);

		var statusSpan = E('span', {
			'id': 'diag-action-status',
			'style': 'margin-left: 12px; font-weight: 600; color: #10b981;'
		}, '');

		var setStatus = function(msg, isErr) {
			statusSpan.style.color = isErr ? '#ef4444' : '#10b981';
			statusSpan.textContent = msg;
			setTimeout(function() {
				if (statusSpan.textContent === msg)
					statusSpan.textContent = '';
			}, 4500);
		};

		var btnRefresh = E('button', {
			'class': 'btn cbi-button cbi-button-apply',
			'style': 'margin-right: 10px;',
			'click': ui.createHandlerFn(this, function() {
				setStatus('⏳ 正在实时采集全链路性能指标与插件日志...', false);
				return this.runDiagReport().then(function(out) {
					textarea.value = out || '';
					setStatus('✅ 最新运行诊断报告已刷新！', false);
				}).catch(function(err) {
					setStatus('❌ 采集失败: ' + err, true);
				});
			})
		}, [ '🔄 重新采集最新数据' ]);

		var btnDownload = E('button', {
			'class': 'btn cbi-button cbi-button-action important',
			'style': 'margin-right: 10px;',
			'click': function() {
				var content = textarea.value || '';
				if (!content) {
					setStatus('❌ 报告内容为空，请先点击重新采集', true);
					return;
				}
				var now = new Date();
				var pad = function(n) { return n < 10 ? '0' + n : '' + n; };
				var stamp = now.getFullYear() + pad(now.getMonth() + 1) + pad(now.getDate()) + '-' +
				            pad(now.getHours()) + pad(now.getMinutes()) + pad(now.getSeconds());
				var filename = 'openwrt-diag-report-' + stamp + '.txt';
				var blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
				var url = URL.createObjectURL(blob);
				var a = document.createElement('a');
				a.href = url;
				a.download = filename;
				document.body.appendChild(a);
				a.click();
				document.body.removeChild(a);
				setTimeout(function() { URL.revokeObjectURL(url); }, 1500);
				setStatus('📥 已下载文件: ' + filename + '（可直接发给 AI 分析）', false);
			}
		}, [ '📥 一键下载诊断日志 (.txt)' ]);

		var btnCopy = E('button', {
			'class': 'btn cbi-button cbi-button-save',
			'click': function() {
				var content = textarea.value || '';
				if (!content) {
					setStatus('❌ 报告内容为空', true);
					return;
				}
				if (navigator.clipboard && navigator.clipboard.writeText) {
					navigator.clipboard.writeText(content).then(function() {
						setStatus('📋 已复制到剪贴板！可直接粘贴发送给 AI 分析', false);
					}).catch(function() {
						textarea.select();
						document.execCommand('copy');
						setStatus('📋 已复制到剪贴板！可直接粘贴发送给 AI 分析', false);
					});
				} else {
					textarea.select();
					document.execCommand('copy');
					setStatus('📋 已复制到剪贴板！可直接粘贴发送给 AI 分析', false);
				}
			}
		}, [ '📋 一键复制全文 (直接粘贴给 AI)' ]);

		return E('div', { 'class': 'cbi-map' }, [
			E('h2', {}, [ '📊 OpenWrt 全链路运行诊断与日志一键导出' ]),
			E('div', { 'class': 'cbi-map-descr', 'style': 'margin-bottom: 14px;' }, [
				'本工具实时采集 CPU 调频/C-States、内存 Slab、主/旁路由拓扑、网卡硬件丢包/BIG TCP/队列卸载、多核软中断均衡 (RPS/XPS/softnet_stat)、BBR/Conntrack 状态、核心守护进程 OOM 保护、DNS 实时解析耗时以及内核/系统日志。',
				E('br'),
				E('strong', {}, '🔒 隐私保护说明：'),
				'报告在生成时已自动脱敏隐去节点服务器地址、密码、UUID、私钥、宽带账号密码及订阅链接，您可放心一键下载 (.txt) 或复制全文发给 AI 进行针对性调优分析。'
			]),
			E('div', { 'style': 'margin-bottom: 14px; display: flex; align-items: center; flex-wrap: wrap; gap: 6px;' }, [
				btnDownload,
				btnCopy,
				btnRefresh,
				statusSpan
			]),
			textarea
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});

