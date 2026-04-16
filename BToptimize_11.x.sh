#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

if [ $(whoami) != "root" ];then
	echo "请使用root权限执行命令！"
	exit 1;
fi
if [ ! -d /www/server/panel ] || [ ! -f /etc/init.d/bt ];then
	echo "未安装宝塔面板"
	exit 1
fi 

echo -e "=============================================================="
echo -e "宝塔Linux面板优化脚本"
echo -e "=============================================================="
echo -e "适用面板版本：11.x"
echo -e "=============================================================="

which php > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo -e "\033[31m未安装PHP，请先安装PHP\033[0m"
	exit 1
fi

read -p "是否继续执行优化脚本？(y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
	echo "已取消执行脚本"
	exit 0
fi

wget -q https://github.com/SenkinAdmin/BTpanel-Free/blob/main/vite.php -O vite.php;
php vite.php /www/server/panel/BTPanel/static/js
if [ $? -ne 0 ]; then
	echo -e "\033[31m清理脚本执行失败\033[0m"
	rm -f vite.php;
	exit 1
fi
rm -f vite.php;

Layout_file="/www/server/panel/BTPanel/templates/default/software.html";
JS_file="/www/server/panel/BTPanel/static/bt.js";
if [ `grep -c "<script src=\"/static/bt.js\"></script>" $Layout_file` -eq '0' ];then
	sed -i 's/<script>window.vite_public_request_token/<script src="\/static\/bt.js"><\/script>&/' $Layout_file;
fi;
wget -q https://github.com/SenkinAdmin/BTpanel-Free/blob/main/bt_new.js -O $JS_file;
echo "已去除各种广告与计算题."

if [ ! -f /www/server/panel/data/view_domain_title_status.pl ]; then
	echo "ignore" > /www/server/panel/data/view_domain_title_status.pl
fi
if [ ! -f /www/server/panel/data/ignore_coupon_time.pl ]; then
	echo "-100" > /www/server/panel/data/ignore_coupon_time.pl
fi
if [ ! -f /www/server/panel/data/is_set_improvement.pl ]; then
	echo "1" > /www/server/panel/data/is_set_improvement.pl
fi
rm -f /www/server/panel/data/improvement.pl
echo "已去除用户体验计划与广告."


sed -i "/htaccess = self.sitePath + '\/.htaccess'/, /public.ExecShell('chown -R www:www ' + htaccess)/d" /www/server/panel/class/panelSite.py
sed -i "/index = self.sitePath + '\/index.html'/, /public.ExecShell('chown -R www:www ' + index)/d" /www/server/panel/class/panelSite.py
sed -i "/doc404 = self.sitePath + '\/404.html'/, /public.ExecShell('chown -R www:www ' + doc404)/d" /www/server/panel/class/panelSite.py
echo "已去除创建网站自动创建的垃圾文件."

#sed -i "s/root \/www\/server\/nginx\/html/return 400/" /www/server/panel/class/panelSite.py
if [ -f /www/server/panel/vhost/nginx/0.default.conf ]; then
	sed -i "s/root \/www\/server\/nginx\/html/return 400/" /www/server/panel/vhost/nginx/0.default.conf
fi
echo "已关闭未绑定域名提示页面."

sed -i "/PluginLoader.daemon_panel()/d" /www/server/panel/task.py
sed -i "/\"check_panel_msg\": check_panel_msg,/d" /www/server/panel/task.py
sed -i "/check_panel_msg,/d" /www/server/panel/task.py
sed -i "/refresh_domain_cache,/d" /www/server/panel/task.py
echo "已去除消息推送与文件校验."

sed -i "/PluginLoader.start_total()/d" /www/server/panel/script/site_task.py
sed -i "/^flush_ssh_log()/d" /www/server/panel/script/site_task.py
sed -i "s/run_thread(cloud_check_domain, (domain,))/return/" /www/server/panel/class/public.py
sed -i "/public.total_keyword(get.query)/d" /www/server/panel/class/panelPlugin.py
sed -i "/public.run_thread(self.get_cloud_list_status, args=(get,))/d" /www/server/panel/class/panelPlugin.py
sed -i "/public.run_thread(self.is_verify_unbinding, args=(get,))/d" /www/server/panel/class/panelPlugin.py
echo "已去除面板日志与绑定域名上报."

if [ ! -f /www/server/panel/data/not_workorder.pl ]; then
	echo "True" > /www/server/panel/data/not_workorder.pl
fi
echo "已关闭在线客服."

if [ "$1" != "no" ]; then
	/etc/init.d/bt restart
else
	echo -e "\033[32m请自行重启面板\033[0m"
fi

echo -e "=============================================================="
echo -e "\033[32m宝塔Linux面板优化脚本执行完毕，按Ctrl+F5刷新后生效\033[0m"
echo -e "=============================================================="
