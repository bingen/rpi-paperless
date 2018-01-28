# https://github.com/adamcharnock/swiftwind-heroku/blob/master/swiftwind_heroku/management/commands/create_superuser_with_password.py
from django.contrib.auth.management.commands import createsuperuser
from django.core.management import CommandError


class Command(createsuperuser.Command):
    help = 'Create a superuser, and allow password to be provided'

    def add_arguments(self, parser):
        super(Command, self).add_arguments(parser)
        parser.add_argument(
            '--password', dest='password', default=None,
            help='Specifies the password for the superuser.',
        )

    def handle(self, *args, **options):
        password = options.get('password')
        username = options.get('username')
        database = options.get('database')

        if password and not username:
            raise CommandError("--username is required if specifying --password")

        try:
            user = self.UserModel._default_manager.db_manager(database).get(username=username)
        except:
            user = None

        if not user:
            super(Command, self).handle(*args, **options)

        if password:
            user = self.UserModel._default_manager.db_manager(database).get(username=username)
            user.set_password(password)
            user.save()
